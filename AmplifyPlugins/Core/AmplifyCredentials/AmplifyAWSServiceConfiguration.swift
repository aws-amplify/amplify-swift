//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Convenience class that is used by Amplify to include metadata such as values for a "User-Agent" during
/// server interactions.
///
/// - Tag: AmplifyAWSServiceConfiguration
public class AmplifyAWSServiceConfiguration {

    /// - Tag: AmplifyAWSServiceConfiguration.amplifyVersion
    public static let amplifyVersion = "2.35.3"

    /// - Tag: AmplifyAWSServiceConfiguration.platformName
    public static let platformName = "amplify-swift"

    public static let userAgentLib: String = "lib/\(platformName)#\(amplifyVersion)"

    @MainActor
    public static let userAgentOS: String = "os/\(DeviceInfo.current.operatingSystem.name)#\(DeviceInfo.current.operatingSystem.version)"
}
