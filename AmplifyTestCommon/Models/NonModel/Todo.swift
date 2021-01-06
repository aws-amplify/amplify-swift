//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation
/*
The schema used to codegen this model:
 type Todo @model {
   id: ID!
   name: String!
   description: String
   categories: [Category]
   section: Section
   stickies: [String]
 }

 type Category {
   name: ID!
   color: Color!
 }

 type Color {
   name: String!
   red: Int!
   green: Int!
   blue: Int!
 }

 type Section {
   name: ID!
   number: Float!
 }
 */

public struct Todo: Model {
    public let id: String
    public var name: String
    public var description: String?
    public var categories: [Category]?
    public var section: Section?
    public var stickies: [String]?

    public init(id: String = UUID().uuidString,
                name: String,
                description: String? = nil,
                categories: [Category]? = [],
                section: Section? = nil,
                stickies: [String]? = []) {
        self.id = id
        self.name = name
        self.description = description
        self.categories = categories
        self.section = section
        self.stickies = stickies
    }
}
