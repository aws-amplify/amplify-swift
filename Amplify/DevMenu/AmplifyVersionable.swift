//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Implement this protocol to support versioning in your plugin
public protocol AmplifyVersionable {
    var version: String { get }
}

public extension AmplifyVersionable where Self: AnyObject {
    var version: String {
        let bundle = Bundle(for: type(of: self))
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version ?? "Not Available"
    }
}
