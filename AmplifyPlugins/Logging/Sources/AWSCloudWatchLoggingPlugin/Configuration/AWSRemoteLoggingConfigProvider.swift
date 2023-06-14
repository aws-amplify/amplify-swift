//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify
import AWSPluginsCore

public class DefaultRemoteLoggingConstraintsProvider: RemoteLoggingConstraintsProvider {    
    public let refreshIntervalInSeconds: Int
    let endpoint: URL
    let credentialProvider: AWSCredentialsProvider?
    
    public init(
         endpoint: URL,
         credentialProvider: AWSCredentialsProvider? = nil,
         refreshIntervalInSeconds: Int = 1200
    ) {
        self.endpoint = endpoint
        self.credentialProvider = credentialProvider
        self.refreshIntervalInSeconds = refreshIntervalInSeconds
    }
    
    public func fetchLoggingConstraints() async throws -> LoggingConstraints {
        throw AWSCloudWatchLoggingError.sessionInternalErrorForUserId
    }
}
