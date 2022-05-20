//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime
import AWSPinpoint
import AWSPluginsCore
import Foundation

/// Conforms to `AWSPinpointBehavior` by storing an instance of the `AWSPinpoint` to expose AWS Pinpoint functionality
class AWSPinpointAdapter: AWSPinpointBehavior {
    let pinpoint: PinpointContext

    convenience init(appId: String,
                     region: String,
                     credentialsProvider: CredentialsProvider) throws {
        // TODO: Do we stil need appID?
        let pinpointConfiguration = try PinpointClient.PinpointClientConfiguration(credentialsProvider: credentialsProvider,
                                                                                   frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData(),
                                                                                   region: region)
        let pinpoint = PinpointContext(with: pinpointConfiguration)
        self.init(pinpoint: pinpoint)
    }

    init(pinpoint: PinpointContext) {
        self.pinpoint = pinpoint
    }

    func getEscapeHatch() -> PinpointClientProtocol {
        pinpoint.pinpointClient
    }
}
