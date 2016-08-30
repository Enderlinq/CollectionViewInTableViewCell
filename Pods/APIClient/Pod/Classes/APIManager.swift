//
//  Manager+Plus.swift
//  Pods
//
//  The MIT License (MIT)
//
//  Created by mrandall on 12/22/15.
//  Copyright © 2015 mark-randall. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Alamofire


//MARK: - APIManager Request encoding

public enum APIClientParameterEncoding: String {
    case URL
    case JSON
}


//MARK: - RequestResponder

public protocol RequestResponder {
    
    /// Handle a successful request
    ///
    /// - Parameter request: APIRequest
    /// - Parameter response: Response<AnyObject, NSError>
    func requestSucceeded(request: APIRequest, response: Response<AnyObject, NSError>)
    
    /// Handle a failed request
    ///
    /// - Parameter request: APIRequest
    /// - Parameter response: Response<AnyObject, NSError>
    func requestFailed(request: APIRequest, response: Response<AnyObject, NSError>)
}


//MARK: - MakeStreamingRequestResult

public enum MakeStreamingRequestResult {
    case Success(task: NSURLSessionUploadTask)
    case Failure(error: NSError)
}


//MARK: - APIManager

public class APIManager: Manager, RequestResponder {
    
    //base URL for Requests
    public var baseURL: NSURL = NSURL()
    
    //Headers to add to every JSONHTTPRequest request
    public var headers: [String: String] = [:]
    
    //Request encoding type
    public var parameterEncoding: APIClientParameterEncoding = .URL
    

    //MARK: - Create / Make Request
    
    /// Create Alamofire Request
    ///
    /// - Parameter withAPIRequest:APIRequest
    /// - Return Request?
    public func createRequest(withAPIRequest request: APIRequest) -> Request? {
        
        //prepare headers
        var headers = self.headers
        headers += Manager.defaultHTTPHeaders
        headers += request.headers
        
        //create full URL
        let URL: NSURL
        if [Alamofire.Method.POST, Alamofire.Method.PUT, Alamofire.Method.PATCH].filter({ $0 == request.method }).last != nil  {
            //handle querystrings in request.path
            URL = URLWithQueryString(forRequest: request)
        } else {
            URL = baseURL.URLByAppendingPathComponent(request.path)
        }
        
        //create Alamofire request / task
        let alamoFireRequest: Alamofire.Request
        if let binaryDataMultipart = request.binaryDataMultipart {
            
            //Assert for debug but allow
            if request.requestTimeoutInterval != nil {
                assertionFailure("APIRequest 'requestTimeoutInterval' currently only supported for data tasks.")
            }
            
            //create multipart form data in memory
            let formData = MultipartFormData()
            for (k,v) in binaryDataMultipart {
                formData.appendBodyPart(data: v, name: k)
            }
            headers += ["Content-Type": formData.contentType]
            do {
                let binaryData = try formData.encode()
                
                //create update load task
                alamoFireRequest = upload(request.method, URL.absoluteString, headers: headers, data: binaryData)
            } catch  {
                //binary encode failed
                request.requestFailed(withResponse: Response<AnyObject, NSError>(request: nil, response: nil, data: nil, result: Result.Failure(error as NSError)))
                return nil
            }
            
        } else if let binaryData = request.binaryData {
            
            //Assert for debug but allow
            if request.requestTimeoutInterval != nil {
                assertionFailure("APIRequest 'requestTimeoutInterval' currently only supported for data tasks.")
            }
            
            //create update load task
            alamoFireRequest = upload(request.method, URL.absoluteString, headers: headers, data: binaryData)
            
        } else {
            
            //create data task
            let parameterEncoding = alamofireEncoding(forRequest: request)
            
            //APIRequest requestTimeoutInterval support:
            //
            //Check if request needs to support requestTimeoutInterval
            //If set create Alamofire.Request 
            //Access its NSURLRequest
            //Create a NSMutableURLRequest from it
            //Set timeoutInterval
            //Create Alamofire.Request from NSMutableURLRequest
            if let requestTimeoutInterval = request.requestTimeoutInterval {
                
                let alamoFireRequestTemp = self.request(
                    request.method,
                    URL.absoluteString,
                    parameters: request.params,
                    encoding: parameterEncoding,
                    headers: headers
                )
                
                if let mutableURLRequest = alamoFireRequestTemp.request?.mutableCopy() as? NSMutableURLRequest {
                    mutableURLRequest.timeoutInterval = requestTimeoutInterval
                    alamoFireRequest = self.request(mutableURLRequest)
                } else {
                    assertionFailure("APIRequest 'requestTimeoutInterval' configuration failed.")
                    alamoFireRequest = alamoFireRequestTemp
                }
                
            } else {
                
                alamoFireRequest = self.request(
                    request.method,
                    URL.absoluteString,
                    parameters: request.params,
                    encoding: parameterEncoding,
                    headers: headers
                )
            }
        }

        alamoFireRequest.validate().responseJSON() { response in
            switch response.result {
            
            case .Success(_):
                self.requestSucceeded(request, response: response)
            
            case .Failure(_):
                
                //4/20/16
                //responseJSON() Fails a empty response always, unless 204
                //If status code valid and response empty succeed
                let acceptableStatusCodes: Range<Int> = 200..<300
                if
                    let statusCode = response.response?.statusCode where acceptableStatusCodes.contains(statusCode),
                    let data = response.data where data.length == 0
                {
                    let response = Response<AnyObject, NSError>(request: nil, response: nil, data: nil, result: Result.Success(""))
                    self.requestSucceeded(request, response: response)
                } else {
                    self.requestFailed(request, response: response)
                }
            }
        }
        
        return alamoFireRequest
    }
    
    /// Create and Resume Alamofire Request
    ///
    /// - Parameter withAPIRequest:APIRequest
    /// - Return Request?
    public func makeRequest(withAPIRequest request: APIRequest) -> Request? {
        let request = self.createRequest(withAPIRequest: request)
        request?.task.resume()
        return request
    }
    
    
    //MARK: - Make / Create Streaming Request
    
    /// Create NSURLSessionUploadTask
    ///
    /// - Parameter withAPIRequest:APIRequest
    /// - Parameter completion: (result: MakeStreamingRequestResult) -> Void
    public func createStreamingRequest(withAPIRequest request: APIRequest, completion: (result: MakeStreamingRequestResult) -> Void) {
        
        //Assert for debug but allow
        if request.requestTimeoutInterval != nil {
            assertionFailure("APIRequest 'requestTimeoutInterval' currently only supported for data tasks.")
        }
        
        //prepare headers
        var headers = self.headers
        headers += request.headers
        
        //create full URL
        let URL = self.baseURL.URLByAppendingPathComponent(request.path)
        
        upload(request.method, URL, headers: headers, multipartFormData: { (data) in
            for (k,v) in request.binaryDataMultipart! {
                data.appendBodyPart(data: v, name: k)
            }
            }, encodingMemoryThreshold: Alamofire.Manager.MultipartFormDataEncodingMemoryThreshold)
            { result in
                
                switch result {
                case .Success(let alamofireRequest, _, _):
                    completion(result: MakeStreamingRequestResult.Success(task: alamofireRequest.task as! NSURLSessionUploadTask))
                case .Failure(let error):
                    completion(result: MakeStreamingRequestResult.Failure(error: error as NSError))
                }
        }
    }
    
    /// Create and Make NSURLSessionUploadTask
    ///
    /// - Parameter withAPIRequest:APIRequest
    /// - Parameter completion: (result: MakeStreamingRequestResult) -> Void
    public func makeStreamingRequest(withAPIRequest request: APIRequest, completion: (result: MakeStreamingRequestResult) -> Void) {
        
        createStreamingRequest(withAPIRequest: request) { response in
            
            switch response {
            case .Success(let task):
                task.resume()
                completion(result: MakeStreamingRequestResult.Success(task: task))
            case .Failure(let error):
                completion(result: MakeStreamingRequestResult.Failure(error: error as NSError))
            }
        }
    }
    
    
    //MARK: - Make / Create Download Request
    
    /// Create Alamofire Download Request
    ///
    /// - Parameter withAPIRequest:APIRequest
    /// - Return Request?
    public func createDownloadRequest(withAPIRequest request: APIRequest, streamToURL url: NSURL) -> Request? {
        
        //Assert for debug but allow
        if request.requestTimeoutInterval != nil {
            assertionFailure("APIRequest 'requestTimeoutInterval' currently only supported for data tasks.")
        }
        
        //prepare headers
        var headers = self.headers
        headers += request.headers
        
        //create full URL
        let URL = baseURL.URLByAppendingPathComponent(request.path)
        
        //encoding
        let parameterEncoding = alamofireEncoding(forRequest: request)
        
        return download(request.method, URL, parameters: request.params, encoding: parameterEncoding, headers: headers) { (temporaryURL, response) in
            return url
        }
    }
    
    /// Create and Resume Alamofire Download Request
    ///
    /// - Parameter withAPIRequest:APIRequest
    /// - Return Request?
    public func makeDownloadRequest(withAPIRequest request: APIRequest, streamToURL url: NSURL) -> Request? {
        let alamofireRequestTask = self.createDownloadRequest(withAPIRequest: request, streamToURL: url)
        alamofireRequestTask?.resume()
        return alamofireRequestTask
    }
    
    
    //MARK: - RequestResponder
    
    public func requestSucceeded(request: APIRequest, response: Response<AnyObject, NSError>) {
        request.requestSucceeded(withResponse: response)
    }
    
    public func requestFailed(request: APIRequest, response: Response<AnyObject, NSError>) {
        request.requestFailed(withResponse: response)
    }
    
    
    //MARK: - Create / Make Request Helpers
    
    /// Creates URL with NSURLQueryItem in request.path
    ///
    /// - Parameter forRequest: APIRequest
    /// - Return NSURL
    private func URLWithQueryString(forRequest request: APIRequest) -> NSURL {
        
        //split on '?'
        let querySplit = request.path.split(Character("?"))
        guard
            querySplit.count == 2,
            let path = querySplit.first,
            let queryString = querySplit.last
            else {
                return baseURL.URLByAppendingPathComponent(request.path)
        }
        
        //create NSURLComponents with baseURL and path
        guard let taskComponents = NSURLComponents(URL: self.baseURL.URLByAppendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            return baseURL.URLByAppendingPathComponent(path)
        }
        
        //split queryString on '&'
        //reduce queryStringKeyValues into [NSURLQueryItem]
        taskComponents.queryItems = queryString.split(Character("&")).reduce([NSURLQueryItem]()) { (var queryItems, string) in
            
            //split on '='
            let queryStringKeyValue = string.split(Character("="))
            guard
                queryStringKeyValue.count == 2,
                let key = queryStringKeyValue.first,
                let value = queryStringKeyValue.last
                else {
                    return queryItems
            }
            
            queryItems.append(NSURLQueryItem(name: key, value: value))
            return queryItems
        }
        
        guard let URLWithQueryString = taskComponents.URL else {
            return baseURL.URLByAppendingPathComponent(path)
        }
        
        return URLWithQueryString
    }
    
    //MARK: - Determine URL Encoding for Request
    
    /// Mapps request.parameterEncoding (HTTPRequestParameterEncoding) to Alamofire.ParameterEncoding
    ///
    /// - Parameter forRequest: APIRequest
    /// - Return Alamofire.ParameterEncoding
    private func alamofireEncoding(forRequest request: APIRequest) -> Alamofire.ParameterEncoding {
        
        guard [Alamofire.Method.POST, Alamofire.Method.PUT, Alamofire.Method.PATCH].filter({ $0 == request.method }).last != nil else {
            return Alamofire.ParameterEncoding.URL
        }
        
        let clientParameterEncoding: Alamofire.ParameterEncoding
        switch parameterEncoding {
        case .URL:
            clientParameterEncoding = .URL
        case .JSON:
            clientParameterEncoding = .JSON
        }
        
        let requestParameterEncoding: Alamofire.ParameterEncoding
        switch request.parameterEncoding {
        case .URL:
            requestParameterEncoding = .URL
        case .JSON:
            requestParameterEncoding = .JSON
        case .CLIENTDEFAULT:
            requestParameterEncoding = clientParameterEncoding
        }
        
        return requestParameterEncoding
    }
}

//MARK: - Top Level Helpers

private func +=<K, V> (inout left: [K : V], right: [K : V]) {
    for (k, v) in right {
        left[k] = v
    }
}

private extension String {
    func split(delimiter: Character) -> [String] {
        return self.characters.split { $0 == delimiter }.map(String.init)
    }
}