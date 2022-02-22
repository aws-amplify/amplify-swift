//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol StorageBackgroundEventsHandler {
    var backgroundEventCompletionHandler: (() -> Void)? { get set }
}

public class StorageRegistry {
    static var handlers: [String: StorageBackgroundEventsHandler] = [:]

    public static func handleBackgroundEvent(identifier: String, completionHandler: @escaping () -> Void) -> Bool {
        if var handler = handlers[identifier] {
            handler.backgroundEventCompletionHandler = completionHandler
            return true
        } else {
            return false
        }
    }

    // MARK: - Internal -

    static func register(identifier: String, backgroundEventsHandler: StorageBackgroundEventsHandler) {
        handlers[identifier] = backgroundEventsHandler
    }

    static func unregister(identifier: String) {
        handlers[identifier] = nil
    }

    static func findCompletionHandler(for identifier: String) -> (() -> Void)? {
        guard let handler = handlers[identifier],
                let completionHandler = handler.backgroundEventCompletionHandler else {
                    return nil
                }
        return completionHandler
    }

}
