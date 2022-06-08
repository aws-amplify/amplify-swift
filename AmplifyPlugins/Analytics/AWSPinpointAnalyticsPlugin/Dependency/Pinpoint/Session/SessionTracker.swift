//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class SessionTracker: InternalPinpointClient {
    unowned var context: PinpointContext

    init(context: PinpointContext) {
        self.context = context
    }
    
    var currentSession: PinpointSession {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
}
