//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPinpoint
import AWSMobileClient
import AWSPluginsCore

/// Conforms to `AWSPinpointBehavior` by storing an instance of the `AWSPinpoint` to expose AWS Pinpoint functionality
class AWSPinpointAdapter: AWSPinpointBehavior {

    let pinpoint: AWSPinpoint
    //let eventRecorder: AWSPinpointEventRecorder

    convenience init(pinpointAnalyticsAppId: String,
                     pinpointAnalyticsRegion: AWSRegionType,
                     pinpointTargetingRegion: AWSRegionType,
                     cognitoCredentialsProvider: AWSCognitoCredentialsProvider) throws {

        let pinpointConfiguration = AWSPinpointConfiguration(appId: pinpointAnalyticsAppId, launchOptions: nil)
        let serviceConfiguration = AmplifyAWSServiceConfiguration(region: pinpointAnalyticsRegion,
                                                                  credentialsProvider: cognitoCredentialsProvider)
        let targetingServiceConfiguration = AmplifyAWSServiceConfiguration(region: pinpointTargetingRegion,
                                                                           credentialsProvider: cognitoCredentialsProvider)

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
