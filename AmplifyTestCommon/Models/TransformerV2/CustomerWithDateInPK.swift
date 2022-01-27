//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct CustomerWithDateInPK: Model {
    public let id: String
    public var dob: Temporal.DateTime
    public var firstName: String?
    public var lastName: String?
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?

    public init(id: String = UUID().uuidString,
                dob: Temporal.DateTime,
                firstName: String? = nil,
                lastName: String? = nil) {
        self.init(id: id,
                  dob: dob,
                  firstName: firstName,
                  lastName: lastName,
                  createdAt: nil,
                  updatedAt: nil)
    }
    internal init(id: String = UUID().uuidString,
                  dob: Temporal.DateTime,
                  firstName: String? = nil,
                  lastName: String? = nil,
                  createdAt: Temporal.DateTime? = nil,
                  updatedAt: Temporal.DateTime? = nil) {
        self.id = id
        self.dob = dob
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
