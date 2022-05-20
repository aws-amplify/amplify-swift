//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation

class PinpointContext {
    let pinpointClient: PinpointClientProtocol

    lazy var analyticsClient: AnalyticsClient = {
        AnalyticsClient(context: self)
    }()
    
    lazy var targetingClient: EndpointClient = {
        EndpointClient(context: self)
    }()
    
    lazy var sessionTracker: SessionTracker = {
        SessionTracker(context: self)
    }()
    
    init(with configuration: PinpointClient.PinpointClientConfiguration) {
        pinpointClient = PinpointClient(config: configuration)
    }
    
    var legacyUniqueId: String {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
}

class InternalPinpointClient {
    unowned let context: PinpointContext // ⚠️ This is known to be risky

    init(context: PinpointContext) {
        self.context = context
    }
}
