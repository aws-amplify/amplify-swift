//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSClientRuntime

public class AmplifyAWSServiceConfiguration {
    public static let version = "2.0.1"
    public static let platformName = "amplify-ios"

    public static func frameworkMetaData() -> FrameworkMetadata {

        guard let flutterVersion = platformMapping[Platform.flutter] else {
            return FrameworkMetadata(name: platformName, version: version)
        }
        return FrameworkMetadata(name: Platform.flutter.rawValue,
                                 version: flutterVersion,
                                 extras: [platformName: version])
    }
}
