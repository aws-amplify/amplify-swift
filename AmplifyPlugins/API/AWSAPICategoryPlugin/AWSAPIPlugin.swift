//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

final public class AWSAPIPlugin: NSObject, APICategoryPlugin, AWSAPIAuthInformation {
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

    /// The underlying map that retains instances of NetworkReachabilityNotifier.  Using a computed property
    /// to work around @available for use on stored properties
    var iReachabilityMap: [String: Any]?

    var authProviderFactory: APIAuthProviderFactory

    var reachabilityMap: [String: NetworkReachabilityNotifier] {
        get {
            if iReachabilityMap == nil {
                iReachabilityMap = [String: NetworkReachabilityNotifier]()
            }
            return iReachabilityMap as! [String: NetworkReachabilityNotifier] // swiftlint:disable:this force_cast
        }
        set {
            iReachabilityMap = newValue
        }
    }

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
        self.reachabilityMapLock = NSLock()
        super.init()

        modelRegistration?.registerModels(registry: ModelRegistry.self)
        ModelListDecoderRegistry.registerDecoder(AppSyncListDecoder.self)
        let sessionFactory = sessionFactory
            ?? URLSessionFactory.makeDefault()
        self.session = sessionFactory.makeSession(withDelegate: self)
    }
}

extension URLSessionFactory {
    static func makeDefault() -> URLSessionFactory {
        let configuration = URLSessionConfiguration.default
        let factory = URLSessionFactory(configuration: configuration, delegateQueue: nil)
        return factory
    }
}

extension AWSAPIPlugin: AmplifyVersionable { }
