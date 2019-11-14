//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPinpoint
import AWSMobileClient

/// Conforms to `AWSPinpointBehavior` by storing an instance of the `AWSPinpoint` to expose AWS Pinpoint functionality
class AWSPinpointAdapter: AWSPinpointBehavior {

    let pinpoint: AWSPinpoint
    //let eventRecorder: AWSPinpointEventRecorder

    convenience init(pinpointAnalyticsAppId: String,
                     pinpointAnalyticsRegion: AWSRegionType,
                     pinpointTargetingRegion: AWSRegionType,
                     cognitoCredentialsProvider: AWSCognitoCredentialsProvider) throws {

        let pinpointConfiguration = AWSPinpointConfiguration(appId: pinpointAnalyticsAppId, launchOptions: nil)

        guard let serviceConfiguration = AWSServiceConfiguration(region: pinpointAnalyticsRegion,
                                                                 credentialsProvider: cognitoCredentialsProvider) else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.pinpointAnalyticsServiceConfigurationError.errorDescription,
                AnalyticsErrorConstants.pinpointAnalyticsServiceConfigurationError.recoverySuggestion)
        }

        guard let targetingServiceConfiguration =
            AWSServiceConfiguration(region: pinpointTargetingRegion,
                                    credentialsProvider: cognitoCredentialsProvider) else {

            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.pinpointTargetingServiceConfigurationError.errorDescription,
                AnalyticsErrorConstants.pinpointTargetingServiceConfigurationError.recoverySuggestion)
        }

        pinpointConfiguration.serviceConfiguration = serviceConfiguration
        pinpointConfiguration.targetingServiceConfiguration = targetingServiceConfiguration
        pinpointConfiguration.enableAutoSessionRecording = true

        let pinpoint = AWSPinpoint(configuration: pinpointConfiguration)

        self.init(pinpoint: pinpoint)
    }

    init(pinpoint: AWSPinpoint) {
        self.pinpoint = pinpoint
        //self.eventRecorder = pinpoint.analyticsClient.eventRecorder
    }

    func getEscapeHatch() -> AWSPinpoint {
        return pinpoint
    }
}
