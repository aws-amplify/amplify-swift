//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSPluginsCore

class OIDCBasedConnectionPool: SubscriptionConnectionPool {

    private let tokenProvider: AuthTokenProvider
    var endPointToProvider: [String: ConnectionProvider]

    init(_ tokenProvider: AuthTokenProvider) {
        self.tokenProvider = tokenProvider
        self.endPointToProvider = [:]
    }

    func connection(for url: URL) -> SubscriptionConnection {

        let connectionProvider = endPointToProvider[url.absoluteString] ?? createConnectionProvider(for: url)
        endPointToProvider[url.absoluteString] = connectionProvider
        let connection = AppSyncSubscriptionConnection(provider: connectionProvider)
        return connection
    }

    func createConnectionProvider(for url: URL) -> ConnectionProvider {
        let provider = ConnectionPoolFactory.createConnectionProvider(for: url)
        if let messageInterceptable = provider as? MessageInterceptable {
            messageInterceptable.addInterceptor(CognitoUserPoolsAuthInterceptor(tokenProvider))
        }
        if let connectionInterceptable = provider as? ConnectionInterceptable {
            connectionInterceptable.addInterceptor(RealtimeGatewayURLInterceptor())
            connectionInterceptable.addInterceptor(CognitoUserPoolsAuthInterceptor(tokenProvider))
        }

        return provider
    }

}
