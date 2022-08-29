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
public class StorageBackgroundEventsRegistry {
    public typealias StorageBackgroundEventsHandler = () -> Void

    static var identifiers: Set<String> = []
    static var handlers: [String: StorageBackgroundEventsHandler] = [:]

    /// Handles background events for URLSession on iOS.
    /// - Parameters:
    ///   - identifier: session identifier
    ///   - completionHandler: completion handler
    /// - Returns: indiciates if the identifier was registered and will be handled
    public static func handleBackgroundEvent(identifier: String, completionHandler: @escaping StorageBackgroundEventsHandler) -> Bool {
        if identifiers.contains(identifier) {
            handlers[identifier] = completionHandler
            return true
        } else {
            return false
        }
    }

    // MARK: - Internal -

    // The storage plugin will register the session identifier when it is configured.
    static func register(identifier: String) {
        identifiers.insert(identifier)
    }

    // When the storage function is deinitialized it will unregister the session identifier.
    static func unregister(identifier: String) {
        identifiers.remove(identifier)
    }

    // When URLSession is done processing background events it will use this function to get the completion handler.
    static func findCompletionHandler(for identifier: String) -> StorageBackgroundEventsHandler? {
        handlers[identifier]
    }

    // Once the background event completion handler is used it can be cleared.
    static func removeCompletionHandler(for identifier: String) {
        handlers[identifier] = nil
    }

}
