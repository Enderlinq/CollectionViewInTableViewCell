# API Client Classes

[![CI Status](http://img.shields.io/travis/mrandall/APIClient.svg?style=flat)](https://travis-ci.org/mrandall/APIClient)
[![Version](https://img.shields.io/cocoapods/v/APIClient.svg?style=flat)](http://cocoapods.org/pods/APIClient)
[![License](https://img.shields.io/cocoapods/l/APIClient.svg?style=flat)](http://cocoapods.org/pods/APIClient)
[![Platform](https://img.shields.io/cocoapods/p/APIClient.svg?style=flat)](http://cocoapods.org/pods/APIClient)

## Objective

1. Pattern to define all types (GET, POST, Multi-part, Streaming, POST with query in URL, ...) of requests with a single protocol.
2. Pattern to optionally make this same object also responsible for what may need to a happen between a network request completing and the completion of updating the client applications state with a response.
3. Pattern to easily map Alamofire Response objects to Alamofire Response objects which contain an client application specific error. Allow this to happen on the API level or individual API request level.
4. Not get in the way of anything Alamofire can do. 




## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

APIClient is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "APIClient"
```

## Author

mrandall

## License

APIClient is available under the MIT license. See the LICENSE file for more info.
