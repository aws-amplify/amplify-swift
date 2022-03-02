//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import AWSClientRuntime

public class AmplifyAWSServiceConfiguration {
    static let version = "1.22.0-dev-preview.0"
    static let platformName = "amplify-ios"
    
    public static func frameworkMetaData() -> FrameworkMetadata {
        
        guard let flutterVersion = platformMapping[Platform.flutter] else {
            return FrameworkMetadata(name: platformName, version: version)
        }
        return FrameworkMetadata(name: Platform.flutter.rawValue,
                                 version: flutterVersion,
                                 extras: [platformName: version])
    }
}
