//
//  APIClient.swift
//  Request
//
//  The MIT License (MIT)
//
//  Created by mrandall on 8/29/15.
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

//MARK: HTTP Request

public typealias HTTPRequestMethod = Alamofire.Method

//MARK: - Request Encoding

public enum HTTPRequestParameterEncoding: String {
    case CLIENTDEFAULT
    case URL
    case JSON
}

//MARK: - APIRequestProtocol

public protocol APIRequest {
    
    ///HTTP Method
    var method: HTTPRequestMethod { get }
    
    ///Appended to API Client baseURL
    var path: String { get }
    
    ///Body pararms or QueryString for URL if GET request
    var params: [String: AnyObject] { get }
    
    ///Headers to append to API Client headers
    var headers: [String: String] { get }
    
    //Encoding for HTTP request
    var parameterEncoding: HTTPRequestParameterEncoding { get }
    
    //Optional request level timeout interval
    //NOTE: currently not supported for upload or download tasks only data
    var requestTimeoutInterval: NSTimeInterval? { get }
    
    ///Binary data to be uploaded
    ///If not nil NSURLSessionUploadTask will be made
    var binaryData: NSData? { get }
    
    ///Binary data to be uploaded as multipart data
    ///Name of binaryData and file in the form ['filename':'data']
    ///If not nil and binaryData is not nil multipart NSURLSessionUploadTask will be made
    var binaryDataMultipart: [String:NSData]? { get }
    
    /// Request succeeded
    ///
    /// - Parameter withResponse: Response<AnyObject, NSError>
    func requestSucceeded(withResponse response:  Response<AnyObject, NSError>)
    
    /// Request failed
    ///
    /// - Parameter withResponse: Response<AnyObject, NSError>
    func requestFailed(withResponse response: Response<AnyObject, NSError>)
}

public extension APIRequest {
    
    var method: HTTPRequestMethod { return .GET }
    var path: String { return "" }
    var params: [String: AnyObject] { return [:] }
    var headers: [String: String] { return [:] }
    var parameterEncoding: HTTPRequestParameterEncoding { return .CLIENTDEFAULT }
    var requestTimeoutInterval: NSTimeInterval? { return nil }
    var binaryData: NSData? { return nil }
    var binaryDataMultipart: [String:NSData]? { return nil }
    
    func requestSucceeded(withResponse response: Response<AnyObject, NSError>) { }
    
    func requestFailed(withResponse response: Response<AnyObject, NSError>) { }
}

public extension APIRequest where Self: APIRequestWithCompletion {
    
    func requestSucceeded(withResponse response: Response<AnyObject, NSError>) {
        
        guard let responseValue = response.result.value as? Datatype else {
            return
        }
        
        complete(response, withData: responseValue)
    }
    
    func requestFailed(withResponse response: Response<AnyObject, NSError>) {
        complete(failWithResponse: response)
    }
}

//MARK: - APIRequestWithCompletion

public protocol APIRequestWithCompletion {
    
    //Response data type
    typealias Datatype
    
    /// Response closure
    ///
    /// - Parameter responseResult: RequestResponseResult<T>
    /// - Parameter response: HTTPRequestResponse<T>
    var completion: ((response: Response<Datatype, NSError>) -> Void) { get }
    
    /// Call completion Failure with error
    ///
    /// - Parameter response: Response<AnyObject, NSError>
    /// - Parameter withError: NSError to return from request
    func complete(response: Response<AnyObject, NSError>, withError error: NSError)
    
    /// Call completion Success with data
    /// Data will be cast to Datatype
    ///
    /// - Parameter response: Response<AnyObject, NSError>
    /// - Parameter withData: Datatype
    func complete(response: Response<AnyObject, NSError>, withData data: Datatype)
    
    /// Call completion with response error
    /// Generic error will be returned if response doesn't have an error
    ///
    /// - Parameter failWithResponse: Response<AnyObject, NSError>
    func complete(failWithResponse response: Response<AnyObject, NSError>)
}

public extension APIRequestWithCompletion {
    
    func complete(response: Response<AnyObject, NSError>, withError error: NSError) {
        let response = Response<Datatype, NSError>(request: response.request,
            response: response.response,
            data: response.data,
            result: Result.Failure(error))
        completion(response: response)
    }
    
    func complete(response: Response<AnyObject, NSError>, withData data: Datatype) {
        let response = Response<Datatype, NSError>(request: response.request,
            response: response.response,
            data: response.data,
            result: Result.Success(data))
        completion(response: response)
    }
    
    func complete(failWithResponse response: Response<AnyObject, NSError>) {
        
        guard let error = response.result.error else {
            return
        }
        
        let response = Response<Datatype, NSError>(request: response.request,
            response: response.response,
            data: response.data,
            result: Result.Failure(error))
        completion(response: response)
    }
}