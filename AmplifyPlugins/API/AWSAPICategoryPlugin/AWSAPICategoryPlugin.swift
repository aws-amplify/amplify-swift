//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

final public class AWSAPICategoryPlugin: NSObject, APICategoryPlugin {
    public var key: PluginKey {
        return "AWSAPICategoryPlugin"
    }

    /// A holder for API configurations. This will be populated during the
    /// configuration phase, and is clearable by `reset()`.
    var pluginConfig: AWSAPICategoryPluginConfig!

    /// The provider for Auth services required to access protected APIs. This will be
    /// populated during the configuration phase, and is clearable by `reset()`.
    var authService: AWSAuthServiceBehavior!

    /// The provider for network connections and operations. This will be populated
    /// during initialization, and is clearable by `reset()`.
    var session: URLSessionBehavior!

    /// Maps APIOperations to URLSessionTaskBehavior
    var mapper: OperationTaskMapper

    public init(sessionFactory: URLSessionBehaviorFactory) {
        self.mapper = OperationTaskMapper()
        super.init()
        self.session = sessionFactory.makeSession(withDelegate: self)
    }

    override public init() {
        self.mapper = OperationTaskMapper()
        super.init()

        let configuration = URLSessionConfiguration.default
        let factory = URLSessionFactory(configuration: configuration, delegateQueue: nil)
        self.session = factory.makeSession(withDelegate: self)
    }

}
