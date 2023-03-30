//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public typealias AWSPinpointErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

public struct AWSPinpointErrorConstants {
    static let pinpointConfigurationExpected: AWSPinpointErrorString = (
        "Configuration for Pinpoint is not a dictionary literal",
        "Make sure the value for Pinpoint is a dictionary literal with `AppId` and `Region`"
    )

    static let missingAppId: AWSPinpointErrorString = (
        "AppId is missing",
        "Add AppId to the configuration"
    )

    static let invalidAppId: AWSPinpointErrorString = (
        "AppId is not a string",
        "Ensure AppId is a string"
    )

    static let emptyAppId: AWSPinpointErrorString = (
        "AppId is specified but is empty",
        "AppId should not be empty"
    )

    static let missingRegion: AWSPinpointErrorString = (
        "Region is missing",
        "Add region to the configuration"
    )

    static let invalidRegion: AWSPinpointErrorString = (
        "Region is invalid",
        "Ensure Region is a valid region value"
    )

    static let emptyRegion: AWSPinpointErrorString = (
        "Region is empty",
        "Ensure should not be empty"
    )
    
    public static let deviceOffline: AWSPinpointErrorString = (
        "The device does not have internet access. Please ensure the device is online and try again.",
        ""
    )
}
