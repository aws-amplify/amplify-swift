//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSCore

class IAMBasedConnectionPool: SubscriptionConnectionPool {

    private let credentialProvider: AWSCredentialsProvider
    private let regionType: AWSRegionType
    var endPointToProvider: [String: ConnectionProvider]

    init(_ credentialProvider: AWSCredentialsProvider, region: AWSRegionType) {
        self.credentialProvider = credentialProvider
        self.regionType = region
        self.endPointToProvider = [:]
    }

    func connection(for url: URL, connectionType: SubscriptionConnectionType) -> SubscriptionConnection {

        let connectionProvider = endPointToProvider[url.absoluteString] ?? createConnectionProvider(for: url, connectionType: connectionType)
        endPointToProvider[url.absoluteString] = connectionProvider
        let connection = AppSyncSubscriptionConnection(provider: connectionProvider)
        return connection
    }

    func createConnectionProvider(for url: URL, connectionType: SubscriptionConnectionType) -> ConnectionProvider {
        let provider = ConnectionPoolFactory.createConnectionProvider(for: url, connectionType: connectionType)
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
