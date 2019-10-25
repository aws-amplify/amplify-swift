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

/// The class confirming to AWSPinpointBehavior which uses an instance of the AWSPinpoint to
/// perform its methods. This class acts as a wrapper to expose AWSPinpoint functionality through an
/// instance over a singleton, and allows for mocking in unit tests. The methods contain no other logic other than
/// calling the same method using the AWSPinpoint instance.
class AWSPinpointAdapter: AWSPinpointBehavior {

    let pinpoint: AWSPinpoint

    convenience init(pinpointAnalyticsAppId: String,
                     pinpointAnalyticsRegion: AWSRegionType,
                     pinpointTargetingRegion: AWSRegionType,
                     cognitoCredentialsProvider: AWSCognitoCredentialsProvider) throws {

        let pinpointConfiguration = AWSPinpointConfiguration(appId: pinpointAnalyticsAppId, launchOptions: nil)

        guard let serviceConfiguration = AWSServiceConfiguration(region: pinpointAnalyticsRegion,
                                                                 credentialsProvider: cognitoCredentialsProvider) else {
            throw PluginError.pluginConfigurationError(
                PluginErrorConstants.pinpointAnalyticsServiceConfigurationError.errorDescription,
                PluginErrorConstants.pinpointAnalyticsServiceConfigurationError.recoverySuggestion)
        }

        guard let targetingServiceConfiguration =
            AWSServiceConfiguration(region: pinpointTargetingRegion,
                                    credentialsProvider: cognitoCredentialsProvider) else {

            throw PluginError.pluginConfigurationError(
                PluginErrorConstants.pinpointTargetingServiceConfigurationError.errorDescription,
                PluginErrorConstants.pinpointTargetingServiceConfigurationError.recoverySuggestion)
        }

        pinpointConfiguration.serviceConfiguration = serviceConfiguration
        pinpointConfiguration.targetingServiceConfiguration = targetingServiceConfiguration
        pinpointConfiguration.enableAutoSessionRecording = false

        let pinpoint = AWSPinpoint(configuration: pinpointConfiguration)

        self.init(pinpoint: pinpoint)
    }

    init(pinpoint: AWSPinpoint) {
        self.pinpoint = pinpoint
    }

    // updateEndpoint

    //    func record(_ event: AWSPinpointEvent) {
    //        pinpoint.analyticsClient.record(event)
    //    }

    // startSession

    // stopSession

    // pauseSession

    // func getEscapeHatch() -> AWSPinpoint
}
