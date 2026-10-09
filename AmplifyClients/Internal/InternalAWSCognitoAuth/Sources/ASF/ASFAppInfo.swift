//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyAvailability
import Foundation

package struct ASFAppInfo: ASFAppInfoBehavior {

    package init() {}

    package var name: String? {
        Bundle.main.bundleIdentifier
    }

    package var targetSDK: String {
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

    package var version: String {
        let bundle = Bundle.main
        let buildVersion = bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) ?? ""
        let bundleVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
        return "\(bundleVersion)-\(buildVersion)"
    }

}
