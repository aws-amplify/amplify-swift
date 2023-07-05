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
    let deviceIdentifier: String?
    
    init(userIdentifier: String? = nil) {
        self.userIdentifier = userIdentifier
        #if canImport(WatchKit)
        self.deviceIdentifier = WKInterfaceDevice.current().identifierForVendor?.uuidString
        #elseif canImport(UIKit)
        self.deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString
        #elseif canImport(AppKit)
        self.deviceIdentifier = Host.current().name
        #else
        self.deviceIdentifier = Self.deviceIdentifierFromBundle()
        #endif
    }

    func formattedStreamName() -> String {
        return "\(deviceIdentifier ?? "").\(userIdentifier ?? "guest")"
    }
}
