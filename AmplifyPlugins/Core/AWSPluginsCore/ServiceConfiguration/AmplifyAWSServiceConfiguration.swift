//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSClientRuntime

public class AmplifyAWSServiceConfiguration {
    public static let amplifyVersion = "2.6.0"
    public static let platformName = "amplify-ios"

    public static func frameworkMetaData() -> FrameworkMetadata {

        guard let flutterVersion = platformMapping[Platform.flutter] else {
            return FrameworkMetadata(name: platformName, version: amplifyVersion)
        }
        return FrameworkMetadata(name: Platform.flutter.rawValue,
                                 version: flutterVersion,
                                 extras: [platformName: amplifyVersion])
    }
}
