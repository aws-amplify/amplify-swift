//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

final public class AWSAPIPlugin: NSObject, APICategoryPlugin, APICategoryGraphQLBehaviorExtended, AWSAPIAuthInformation {
    /// The unique key of the plugin within the API category.
    public var key: PluginKey {
        return "awsAPIPlugin"
    }

    /// A holder for API configurations. This will be populated during the
    /// configuration phase, and is clearable by `reset()`.
    var pluginConfig: AWSAPICategoryPluginConfiguration!

    /// The provider for Auth services required to access protected APIs. This will be
    /// populated during the configuration phase, and is clearable by `reset()`.
    var authService: AWSAuthServiceBehavior!

    /// The provider for network connections and operations. This will be populated
    /// during initialization, and is clearable by `reset()`.
    var session: URLSessionBehavior!

    /// Maps APIOperations to URLSessionTaskBehavior
    var mapper: OperationTaskMapper

    /// A queue that regulates the execution of operations. This will be instantiated during initalization phase,
    /// and is clearable by `reset()`. This is implicitly unwrapped to be destroyed when resetting.
    var queue: OperationQueue!

    /// Creating and retrieving connections for subscriptions. This will be instantiated during the configuration phase,
    /// and is clearable by `reset()`. This is implicitly unwrapped to be destroyed when resetting.
    var subscriptionConnectionFactory: SubscriptionConnectionFactory!

    var authProviderFactory: APIAuthProviderFactory

    var reachabilityMap: [String: NetworkReachabilityNotifier]

    /// Lock used for performing operations atomically when getting and setting `reachabilityMap`.
    let reachabilityMapLock: NSLock

    public init(
        modelRegistration: AmplifyModelRegistration? = nil,
        sessionFactory: URLSessionBehaviorFactory? = nil,
        apiAuthProviderFactory: APIAuthProviderFactory? = nil
    ) {
        self.mapper = OperationTaskMapper()
        self.queue = OperationQueue()
        self.authProviderFactory = apiAuthProviderFactory ?? APIAuthProviderFactory()
        self.reachabilityMap = [:]
        self.reachabilityMapLock = NSLock()
        super.init()

        modelRegistration?.registerModels(registry: ModelRegistry.self)
        ModelListDecoderRegistry.registerDecoder(AppSyncListDecoder.self)
        ModelProviderRegistry.registerDecoder(AppSyncModelDecoder.self)
        let sessionFactory = sessionFactory
            ?? URLSessionFactory.makeDefault()
        self.session = sessionFactory.makeSession(withDelegate: self)
    }
}

extension URLSessionFactory {
    static func makeDefault() -> URLSessionFactory {
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        let factory = URLSessionFactory(configuration: configuration, delegateQueue: nil)
        return factory
    }
}

extension AWSAPIPlugin: AmplifyVersionable { }
