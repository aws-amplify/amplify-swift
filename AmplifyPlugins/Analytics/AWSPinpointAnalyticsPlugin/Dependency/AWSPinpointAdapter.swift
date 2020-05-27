//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient
import AWSPinpoint
import AWSPluginsCore
import Foundation

/// Conforms to `AWSPinpointBehavior` by storing an instance of the `AWSPinpoint` to expose AWS Pinpoint functionality
class AWSPinpointAdapter: AWSPinpointBehavior {
    let pinpoint: AWSPinpoint
    // let eventRecorder: AWSPinpointEventRecorder

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

        let pinpoint = AWSPinpoint(configuration: pinpointConfiguration)

        self.init(pinpoint: pinpoint)
    }

    init(pinpoint: AWSPinpoint) {
        self.pinpoint = pinpoint
        // self.eventRecorder = pinpoint.analyticsClient.eventRecorder
    }

    func getEscapeHatch() -> AWSPinpoint {
        pinpoint
    }
}
