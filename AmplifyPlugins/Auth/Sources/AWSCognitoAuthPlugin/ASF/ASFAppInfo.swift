//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyAvailability
import Foundation

struct ASFAppInfo: ASFAppInfoBehavior {

    var name: String? {
        Bundle.main.bundleIdentifier
    }

    var targetSDK: String {
        var targetSDK = ""
#if os(iOS) || os(watchOS) || os(tvOS)
        targetSDK = "\(getIOSVersionMinRequired())"
#elseif os(macOS)
        targetSDK = "\(getMACOSXVersionMinRequired())"
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
