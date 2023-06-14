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
///
/// - Tag: CloudWatchLogStreamNameFormatter
struct CloudWatchLoggingStreamNameFormatter {

    /// - Tag: CloudWatchLogStreamNameFormatter.userIdentifier
    let userIdentifier: String?

    /// - Tag: CloudWatchLogStreamNameFormatter.deviceIdentifier
    let deviceIdentifier: String?
    
    /// - Tag: CloudWatchLogStreamNameFormatter.init
    init(userIdentifier: String? = nil) {
        self.userIdentifier = userIdentifier
        #if canImport(WatchKit)
        self.deviceIdentifier = WKInterfaceDevice.current().identifierForVendor
        #elseif canImport(UIKit)
        self.deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString
        #elseif canImport(AppKit)
        self.deviceIdentifier = Host.current().name
        #else
        self.deviceIdentifier = Self.deviceIdentifierFromBundle()
        #endif
    }

    /// - Returns: String containing a pre-formatted CloudWatch stream name accodring to the
    ///            receiver's properties.
    ///
    /// - Tag: CloudWatchLogStreamNameFormatter.formattedStreamName
    func formattedStreamName() -> String {
        return "\(String(describing: deviceIdentifier)).\(userIdentifier ?? "guest")"
    }
}
