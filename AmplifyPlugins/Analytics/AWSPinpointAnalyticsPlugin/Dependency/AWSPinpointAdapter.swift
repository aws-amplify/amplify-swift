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
                     credentialsProvider: CredentialsProvider,
                     shouldTrackAppSessions: Bool = true) throws {
        var isDebug = false
        #if DEBUG
        isDebug = true
        Amplify.Logging.verbose("Setting PinpointContextConfiguration.isDebug to true")
        #endif

        let configuration = PinpointContextConfiguration(appId: appId,
                                                         region: region,
                                                         credentialsProvider: credentialsProvider,
                                                         isDebug: isDebug,
                                                         shouldTrackAppSessions: shouldTrackAppSessions)
        let pinpoint = try PinpointContext(with: configuration)
        self.init(pinpoint: pinpoint)
    }

    init(pinpoint: PinpointContext) {
        self.pinpoint = pinpoint
    }

    func getEscapeHatch() -> PinpointClientProtocol {
        pinpoint.pinpointClient
    }
}
