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
 This schema has been manually modified to create a schema drift scenario.
 One of the enum cases in EnumDrift has been removed. This allows tests to
 decode data that contains the missing value, fail to decode to this type,
 and to further observe the state of the system (especially in DataStore's sync process).
 Data that contains the missing value needs to be persisted with API directly
 using a custom GraphQL document/variables since model objects cannot be created with the
 commented out enum case.
 */
public enum EnumDrift: String, EnumPersistable {
  case one = "ONE"
  case two = "TWO"
  // case three = "THREE"
}
