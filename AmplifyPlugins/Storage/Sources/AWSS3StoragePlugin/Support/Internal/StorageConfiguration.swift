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
        /// Progress stall timeout in seconds. 0 = disabled.
        static let progressStallTimeoutInterval: TimeInterval = 0
    }

    let sessionIdentifier: String
    let sharedContainerIdentifier: String?
    let allowsCellularAccess: Bool
    let timeoutIntervalForResource: TimeInterval
    /// If progress does not advance for this many seconds, upload is cancelled. 0 = disabled.
    let progressStallTimeoutInterval: TimeInterval

    init(
        sessionIdentifier: String = Defaults.sessionIdentifier,
        sharedContainerIdentifier: String = Defaults.sharedContainerIdentifier,
        allowsCellularAccess: Bool = Defaults.allowsCellularAccess,
        timeoutIntervalForResource: TimeInterval = Defaults.timeoutIntervalForResource,
        progressStallTimeoutInterval: TimeInterval = Defaults.progressStallTimeoutInterval
    ) {
        self.sessionIdentifier = sessionIdentifier
        self.sharedContainerIdentifier = sharedContainerIdentifier
        self.allowsCellularAccess = allowsCellularAccess
        self.timeoutIntervalForResource = timeoutIntervalForResource
        self.progressStallTimeoutInterval = progressStallTimeoutInterval
    }

    init(forBucket bucket: String) {
        self.init(
            sessionIdentifier: "\(Defaults.sessionIdentifier).\(bucket)"
        )
    }

    init(forBucket bucket: String, progressStallTimeoutInterval: TimeInterval = Defaults.progressStallTimeoutInterval) {
        self.init(
            sessionIdentifier: "\(Defaults.sessionIdentifier).\(bucket)",
            progressStallTimeoutInterval: progressStallTimeoutInterval
        )
    }
}
