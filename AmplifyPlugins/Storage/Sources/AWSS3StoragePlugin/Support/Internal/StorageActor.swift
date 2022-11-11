//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@globalActor public final actor StorageActor {
    public static let shared = StorageActor()
}

// Copied from MainActor
extension StorageActor {
    /// Execute the given body closure on the working actor.
    public static func run<T>(resultType: T.Type = T.self, body: @StorageActor @Sendable () throws -> T) async rethrows -> T where T : Sendable {
        try await body()
    }
}

