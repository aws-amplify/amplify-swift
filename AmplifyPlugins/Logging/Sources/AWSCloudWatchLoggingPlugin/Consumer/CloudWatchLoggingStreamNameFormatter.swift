//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

#if canImport(WatchKit)
import WatchKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Responsible for creating pre-formatted CloudWatch stream names.
struct CloudWatchLoggingStreamNameFormatter {

    let userIdentifier: String?
    var deviceIdentifier: String? {
        get async {
            #if canImport(WatchKit)
            await WKInterfaceDevice.current().identifierForVendor?.uuidString
            #elseif canImport(UIKit)
            await UIDevice.current.identifierForVendor?.uuidString
            #elseif canImport(AppKit)
            Host.current().name
            #else
            Self.deviceIdentifierFromBundle()
            #endif
        }
    }

    init(userIdentifier: String? = nil) {
        self.userIdentifier = userIdentifier
    }

    func formattedStreamName() async -> String {
        return "\(await deviceIdentifier ?? "").\(userIdentifier ?? "guest")"
    }
}
