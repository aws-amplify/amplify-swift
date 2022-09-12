//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Foundation.Bundle {
    static func authCognitoTestBundle() -> Bundle {
        let thisModuleName = "Amplify_AWSCognitoAuthPluginUnitTests"
        var url = Bundle.main.bundleURL

        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            url = bundle.bundleURL.deletingLastPathComponent()
        }

        url = url.appendingPathComponent("\(thisModuleName).bundle")

        guard let bundle = Bundle(url: url) else {
            fatalError("Foundation.Bundle.module could not load resource bundle: \(url.path)")
        }

        return bundle
    }
}
