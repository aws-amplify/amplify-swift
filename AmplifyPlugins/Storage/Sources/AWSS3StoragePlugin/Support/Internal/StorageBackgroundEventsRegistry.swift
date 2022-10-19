//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Background events registry.
///
/// Discussion:
///    Multiple URLSession instances could be running background events with their own unique identifier. Those can be run
///    independently of the Amplify Storage plugin and this function will indiciate if it will handle the given identifier.
class StorageBackgroundEventsRegistry {
    typealias StorageBackgroundEventsContinuation = CheckedContinuation<Bool, Never>
    static var identifier: String?
    static var continuation: StorageBackgroundEventsContinuation?

    /// Handles background events for URLSession on iOS.
    /// - Parameters:
    ///   - identifier: session identifier
    ///   - completionHandler: completion handler
    /// - Returns: indicates if the identifier was registered and will be handled
    static func handleEventsForBackgroundURLSession(identifier: String) async -> Bool {
        guard self.identifier == identifier else { return false }

        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            self.continuation = continuation
        }
    }

    // MARK: - Internal -

    // The storage plugin will register the session identifier when it is configured.
    static func register(identifier: String) {
        self.identifier = identifier
    }

    // When the storage function is deinitialized it will unregister the session identifier.
    static func unregister(identifier: String) {
        if self.identifier == identifier {
            self.identifier = nil
        }
    }

    // When URLSession is done processing background events it will use this function to get the completion handler.
    static func getContinuation(for identifier: String) -> StorageBackgroundEventsContinuation? {
        self.identifier == identifier ? continuation : nil
    }

    // Once the background event completion handler is used it can be cleared.
    static func removeContinuation(for identifier: String) {
        if self.identifier == identifier {
            self.continuation = nil
        }
    }

}
