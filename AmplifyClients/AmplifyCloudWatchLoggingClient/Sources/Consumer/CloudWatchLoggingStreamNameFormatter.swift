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
    let storagePathIdentifier: String
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

    init(userIdentifier: String? = nil, storagePathIdentifier: String) {
        self.userIdentifier = userIdentifier
        self.storagePathIdentifier = storagePathIdentifier
    }

    func formattedStreamName() async -> String {
        return await "\(deviceIdentifier ?? "").\(storagePathIdentifier).\(userIdentifier ?? "guest")"
    }

    private static func deviceIdentifierFromBundle() -> String? {
        return Bundle.main.bundleIdentifier
    }
}
