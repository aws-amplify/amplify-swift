//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension String {
    func homeDirectoryResolved() -> Self {
        if let first = self.first, first == "~" {
            return self.replacingCharacters(in: ...self.startIndex,
                                            with: FileManager.default.homeDirectoryForCurrentUser.path)
        }
        return self
    }
}
