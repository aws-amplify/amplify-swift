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
    public static let amplifyVersion = "visionos-preview-0.0.1"

    /// - Tag: AmplifyAWSServiceConfiguration.platformName
    public static let platformName = "amplify-swift"

    public static let userAgentLib: String = "lib/\(platformName)#\(amplifyVersion)"

    public static let userAgentOS: String = "os/\(DeviceInfo.current.operatingSystem.name)#\(DeviceInfo.current.operatingSystem.version)"
}
