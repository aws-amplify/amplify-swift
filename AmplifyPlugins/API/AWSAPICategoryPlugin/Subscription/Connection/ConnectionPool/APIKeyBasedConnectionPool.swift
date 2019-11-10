//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSPluginsCore

class APIKeyBasedConnectionPool: SubscriptionConnectionPool {

    private let apiKeyProvider: APIKeyProvider
    var endPointToProvider: [String: ConnectionProvider]

    init(_ apiKeyProvider: APIKeyProvider) {
        self.apiKeyProvider = apiKeyProvider
        self.endPointToProvider = [:]
    }

    func connection(for url: URL) -> SubscriptionConnection {
        let connectionProvider: ConnectionProvider
        if let cachedProvider = endPointToProvider[url.absoluteString] {
            connectionProvider = cachedProvider
        } else {
            connectionProvider = createConnectionProvider(for: url)
            endPointToProvider[url.absoluteString] = connectionProvider
        }

        let connection = AppSyncSubscriptionConnection(provider: connectionProvider)
        return connection
    }

    func createConnectionProvider(for url: URL) -> ConnectionProvider {
        let provider = ConnectionPoolFactory.createConnectionProvider(for: url)


        if let messageInterceptable = provider as? MessageInterceptable {
            messageInterceptable.addInterceptor(APIKeyAuthInterceptor(apiKeyProvider))
        }
        if let connectionInterceptable = provider as? ConnectionInterceptable {
            connectionInterceptable.addInterceptor(RealtimeGatewayURLInterceptor())
            connectionInterceptable.addInterceptor(APIKeyAuthInterceptor(apiKeyProvider))
        }
        return provider
    }
}
