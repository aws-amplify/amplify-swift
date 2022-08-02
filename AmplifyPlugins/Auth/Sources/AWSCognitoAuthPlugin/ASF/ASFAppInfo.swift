//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ASFAppInfo: ASFAppInfoBehavior {

    var name: String? {
        Bundle.main.bundleIdentifier
    }

    var targetSDK: String {
        var targetSDK: String = ""
#if os(iOS) || os(watchOS) || os(tvOS)
        targetSDK = "\(__IPHONE_OS_VERSION_MIN_REQUIRED)"
#elseif os(macOS)
        targetSDK = "\(__MAC_OS_X_VERSION_MIN_REQUIRED)"
#else
        targetSDK = "Unknown"
#endif
        return targetSDK
    }

    var version: String {
        let bundle = Bundle.main
        let buildVersion = bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) ?? ""
        let bundleVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
        return "\(bundleVersion)-\(buildVersion)"
    }

}
