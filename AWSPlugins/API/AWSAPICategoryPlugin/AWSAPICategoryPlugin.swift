//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

final public class AWSAPICategoryPlugin: APICategoryPlugin {

    /// A holder for API configurations. This will be populated during the
    /// configuration phase, and is clearable by `reset()`.
    var apiConfigurations: [String: JSONValue]!

    /// The provider for Auth services required to access protected APIs. This will be
    /// populated during the configuration phase, and is clearable by `reset()`.
    var authService: AWSAuthServiceBehavior!

    /// The provider for network connections and operations. This will be populated
    /// during initialization, and is clearable by `reset()`.
    var httpTransport: HTTPTransport!

    public var key: PluginKey {
        return "AWSAPICategoryPlugin"
    }

    public convenience init() {
        let defaultHTTPTransport = NSURLSessionHTTPTransport()
        self.init(httpTransport: defaultHTTPTransport)
    }

    init(httpTransport: HTTPTransport) {
        self.httpTransport = httpTransport
    }

}

class AWSAPIOperation {

}

protocol HTTPTransport {
    func reset()
}

protocol HTTPTransportTask {
    var taskIdentifier: Int { get }
}

protocol HTTPTransportTaskDelegate: class {
    func task(_ httpTransportTask: HTTPTransportTask, didReceiveData data: Data)
}

final class NSURLSessionHTTPTransport: HTTPTransport {
    func reset() {
        // TODO: invalidateAndCancel()
    }
}
