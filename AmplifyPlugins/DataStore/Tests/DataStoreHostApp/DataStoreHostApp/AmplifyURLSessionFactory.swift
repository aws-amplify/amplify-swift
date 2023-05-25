//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import AWSAPIPlugin

class AmplifyURLSessionFactory: URLSessionBehaviorFactory {
    func makeSession(withDelegate delegate: URLSessionBehaviorDelegate?) -> URLSessionBehavior {
        let urlSessionDelegate = delegate?.asURLSessionDelegate
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        
        let session = URLSession(configuration: configuration,
                                 delegate: urlSessionDelegate,
                                 delegateQueue: nil)
        return AmplifyURLSession(session: session)
    }


}
