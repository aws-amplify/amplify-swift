//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension String {
    func upperCaseFirstLetter() -> String {
      return prefix(1).uppercased() + lowercased().dropFirst()
    }

    mutating func upperCaseFirstLetter() {
      self = upperCaseFirstLetter()
    }

    func lowerCaseFirstLetter() -> String {
      return prefix(1).lowercased() + lowercased().dropFirst()
    }

    mutating func lowerCaseFirstLetter() {
      self = lowerCaseFirstLetter()
    }
}
