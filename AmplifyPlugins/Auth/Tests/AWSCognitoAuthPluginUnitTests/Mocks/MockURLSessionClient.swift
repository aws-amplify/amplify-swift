//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

class MockURLSessionClient: URLSessionClientBehavior {
    
    public var cancelAndResetCallCount = 0
    public var dataForURLRequestCallCount = 0
    public var dataForURLCallCount = 0
    
    func cancelAndReset() async {
        cancelAndResetCallCount += 1
    }
    
    func data(for request: URLRequest, delegate: (URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
        dataForURLRequestCallCount += 1
        return (Data(), HTTPURLResponse())
    }
    
    func data(from url: URL, delegate: (URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
        dataForURLCallCount += 1
        return (Data(), HTTPURLResponse())
    }
    
}
