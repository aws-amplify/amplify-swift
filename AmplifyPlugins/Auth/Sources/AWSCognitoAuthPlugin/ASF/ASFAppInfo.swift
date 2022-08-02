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
        return "\(__IPHONE_OS_VERSION_MIN_REQUIRED)"
    }

    var version: String {
        let bundle = Bundle.main
        let buildVersion = bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) ?? ""
        let bundleVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
        return "\(bundleVersion)-\(buildVersion)"
    }

}
