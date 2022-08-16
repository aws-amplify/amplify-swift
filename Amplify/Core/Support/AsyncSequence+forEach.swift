//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension AsyncSequence {
    func forEach(_ block: (Element) async throws -> Void) async rethrows {
        for try await element in self {
          try await block(element)
        }
      }
}
