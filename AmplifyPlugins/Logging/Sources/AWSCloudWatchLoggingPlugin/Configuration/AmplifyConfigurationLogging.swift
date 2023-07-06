//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AmplifyConfigurationLogging: Codable {
    public let awsCloudWatchLoggingPlugin: AWSCloudWatchLoggingPluginConfiguration
}
