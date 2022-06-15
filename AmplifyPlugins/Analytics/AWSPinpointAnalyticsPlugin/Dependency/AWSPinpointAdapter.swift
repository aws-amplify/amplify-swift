//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCore
import AWSPinpoint
import AWSPluginsCore
import Foundation

/// Conforms to `AWSPinpointBehavior` by storing an instance of the `AWSPinpoint` to expose AWS Pinpoint functionality
class AWSPinpointAdapter: AWSPinpointBehavior {
    let pinpoint: AWSPinpoint

    convenience init(pinpointAnalyticsAppId: String,
                     pinpointAnalyticsRegion: AWSRegionType,
                     pinpointTargetingRegion: AWSRegionType,
                     credentialsProvider: AWSCredentialsProvider) throws {
        let pinpointConfiguration = AWSPinpointConfiguration(appId: pinpointAnalyticsAppId, launchOptions: nil)
        let serviceConfiguration = AmplifyAWSServiceConfiguration(region: pinpointAnalyticsRegion,
                                                                  credentialsProvider: credentialsProvider)
        let targetingServiceConfiguration = AmplifyAWSServiceConfiguration(region: pinpointTargetingRegion,
                                                                           credentialsProvider: credentialsProvider)

        pinpointConfiguration.serviceConfiguration = serviceConfiguration
        pinpointConfiguration.targetingServiceConfiguration = targetingServiceConfiguration
        pinpointConfiguration.enableAutoSessionRecording = true

        #if DEBUG
        pinpointConfiguration.debug = true
        Amplify.Logging.verbose("Setting pinpointConfiguration.debug to true")
        #endif

        let pinpoint = AWSPinpoint(configuration: pinpointConfiguration)

        self.init(pinpoint: pinpoint)
    }

    init(pinpoint: AWSPinpoint) {
        self.pinpoint = pinpoint
    }

    func getEscapeHatch() -> AWSPinpoint {
        pinpoint
    }
}
