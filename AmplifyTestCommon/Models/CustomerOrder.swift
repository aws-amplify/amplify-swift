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
 type CustomerOrder @model @key(fields: ["orderId", "id"]) {
    id: ID!
    orderId: String!
    email: String!
 }
 
 type CustomPrimary1 @model @key(fields: ["orderId"]) {
    orderId: String!
    id: String
    email: String
 }
 public init(orderId: String = UUID().uuidString,
     email: String) {
     self.orderId = orderId
     self.email = email
 }
 
 type CustomPrimary2 @model @key(fields: ["orderId", "id"]) {
    id: ID!
    orderId: ID!
    email: String
 }
 // Q. constuctor, is this the correct constructor, if so, codegen changes
 public init(id: String = UUID().uuidString,
            orderId: String = UUID().uuidString,
            email: String) {
     self.orderId = orderId
     self.email = email
 }

 type CustomPrimary3 @model @key(fields: ["orderId", "id"]) {
    id: ID!
    orderId: String!
    email: String
 }
 
 // what about other fields like Int? does `amplify push` fail? is it supported?
 
 */
public struct CustomerOrder: Model {
  public let id: String
  public var orderId: String
  public var email: String

  public init(id: String = UUID().uuidString,
      orderId: String,
      email: String) {
      self.id = id
      self.orderId = orderId
      self.email = email
  }
    // CustomPrimary1
    public init(orderId: String = UUID().uuidString,
        email: String) {
        self.orderId = orderId
        self.email = email
    }
}
