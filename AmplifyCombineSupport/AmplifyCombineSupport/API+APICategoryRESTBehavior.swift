//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

public typealias APIRESTPublisher = AnyPublisher<Data, APIError>

public extension APICategoryRESTBehavior {

    /// Perform an HTTP DELETE operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body
    /// - Returns: An APIRESTPublisher that can be observed for its value
    func delete(request: RESTRequest) -> APIRESTPublisher {
        Future { promise in
            _ = self.delete(request: request) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Perform an HTTP GET operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body
    /// - Returns: An APIRESTPublisher that can be observed for its value
    func get(request: RESTRequest) -> APIRESTPublisher {
        Future { promise in
            _ = self.get(request: request) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Perform an HTTP HEAD operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body
    /// - Returns: An APIRESTPublisher that can be observed for its value
    func head(request: RESTRequest) -> APIRESTPublisher {
        Future { promise in
            _ = self.head(request: request) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Perform an HTTP PATCH operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body
    /// - Returns: An APIRESTPublisher that can be observed for its value
    func patch(request: RESTRequest) -> APIRESTPublisher {
        Future { promise in
            _ = self.patch(request: request) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Perform an HTTP POST operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body
    /// - Returns: An APIRESTPublisher that can be observed for its value
    func post(request: RESTRequest) -> APIRESTPublisher {
        Future { promise in
            _ = self.post(request: request) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Perform an HTTP PUT operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body
    /// - Returns: An APIRESTPublisher that can be observed for its value
    func put(request: RESTRequest) -> APIRESTPublisher {
        Future { promise in
            _ = self.put(request: request) { promise($0) }
        }.eraseToAnyPublisher()
    }

}
