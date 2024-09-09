//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct StorageConfiguration {
    enum Defaults {
        static let sessionIdentifier =  "com.amazon.aws.default.identifier"
        static let sharedContainerIdentifier = "com.amazon.aws.default.identifier-shared"
        static let allowsCellularAccess = true
        static let timeoutIntervalForResource = TimeInterval.minutes(50)
    }

    let sessionIdentifier: String
    let sharedContainerIdentifier: String?
    let allowsCellularAccess: Bool
    let timeoutIntervalForResource: TimeInterval

    static let `default`: StorageConfiguration = .init()

    init(
        sessionIdentifier: String = Defaults.sessionIdentifier,
        sharedContainerIdentifier: String = Defaults.sharedContainerIdentifier,
        allowsCellularAccess: Bool = Defaults.allowsCellularAccess,
        timeoutIntervalForResource: TimeInterval = Defaults.timeoutIntervalForResource
    ) {
        self.sessionIdentifier = sessionIdentifier
        self.sharedContainerIdentifier = sharedContainerIdentifier
        self.allowsCellularAccess = allowsCellularAccess
        self.timeoutIntervalForResource = timeoutIntervalForResource
    }
}
