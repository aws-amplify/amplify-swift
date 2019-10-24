//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// An HTTPTransport backed by a URLSession
final class URLSessionHTTPTransport: HTTPTransport {
    func task(for request: APIGetRequest) -> HTTPTransportTask {
        fatalError("Not yet implemented")
    }

    func reset() {
        fatalError("Not yet implemented")
    }
}
