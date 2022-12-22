//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum ApplicationState: String {
    case foreground
    case background
    case inactive

    var pinpointAttribute: (key: String, value: String) {
        let key = "applicationState"
        switch self {
        case .foreground:
            return (key, "UIApplicationStateActive")
        case .background:
            return (key, "UIApplicationStateBackground")
        case .inactive:
            return (key, "UIApplicationStateInactive")
        }
    }
}
