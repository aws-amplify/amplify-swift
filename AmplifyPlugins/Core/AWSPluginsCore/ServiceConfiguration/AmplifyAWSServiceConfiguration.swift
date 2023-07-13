//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSClientRuntime
import Amplify

/// Convenience class that is used by Amplify to include metadata such as values for a "User-Agent" during
/// server interactions.
///
/// - Tag: AmplifyAWSServiceConfiguration
public class AmplifyAWSServiceConfiguration {

    /// - Tag: AmplifyAWSServiceConfiguration.amplifyVersion
    public static let amplifyVersion = "2.14.1"

    /// - Tag: AmplifyAWSServiceConfiguration.platformName
    public static let platformName = "amplify-swift"

    /// Returns basic amount of metadata that includes both
    /// [AmplifyAWSServiceConfiguration.amplifyVersion](x-source-tag://AmplifyAWSServiceConfiguration.amplifyVersion)
    /// and
    /// [AmplifyAWSServiceConfiguration.platformName](x-source-tag://AmplifyAWSServiceConfiguration.platformName)
    /// in addition to the operating system version if `includesOS` is set to `true`.
    ///
    /// - Tag: AmplifyAWSServiceConfiguration.frameworkMetaDataWithOS
    public static func frameworkMetaData(includeOS: Bool = false) -> FrameworkMetadata {
        let osKey = "os"
        guard let flutterVersion = platformMapping[Platform.flutter] else {
            if includeOS {
                return FrameworkMetadata(
                    name: platformName,
                    version: amplifyVersion,
                    extras: [osKey: frameworkOS()]
                )
            }
            return FrameworkMetadata(name: platformName, version: amplifyVersion)
        }
        var extras = [platformName: amplifyVersion]
        if includeOS {
            extras[osKey] = frameworkOS()
        }
        return FrameworkMetadata(name: Platform.flutter.rawValue,
                                 version: flutterVersion,
                                 extras: extras)
    }

    private static func frameworkOS() -> String {
        // Please note that because the value returned by this function will be
        // sanitized by FrameworkMetadata by removing anything not in a special
        // character set that does NOT include the forward slash (/), the
        // backslash (\) is used as a separator instead.
        let separator = "\\"
        let operatingSystem = DeviceInfo.current.operatingSystem
        return [operatingSystem.name, operatingSystem.version].joined(separator: separator)
    }
}
