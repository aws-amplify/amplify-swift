//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSCore
import AWSPluginsCore

class IAMBasedConnectionPool: SubscriptionConnectionPool {

    private let credentialProvider: IAMCredentialsProvider
    private let regionType: AWSRegionType
    var endPointToProvider: [String: ConnectionProvider]

    init(_ credentialProvider: IAMCredentialsProvider, region: AWSRegionType) {
        self.credentialProvider = credentialProvider
        self.regionType = region
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
            messageInterceptable.addInterceptor(IAMAuthInterceptor(credentialProvider, region: regionType))
        }
        if let connectionInterceptable = provider as? ConnectionInterceptable {
            connectionInterceptable.addInterceptor(RealtimeGatewayURLInterceptor())
            connectionInterceptable.addInterceptor(IAMAuthInterceptor(credentialProvider, region: regionType))
        }

        return provider
    }

}
