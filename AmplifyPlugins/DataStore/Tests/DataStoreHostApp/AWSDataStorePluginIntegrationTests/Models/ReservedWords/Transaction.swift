//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Foundation
import Amplify

public struct Transaction: Model {
    public let id: String

    public init(id: String = UUID().uuidString) {
        self.id = id
    }
}
