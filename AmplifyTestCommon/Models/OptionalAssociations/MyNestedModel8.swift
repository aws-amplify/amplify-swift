//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct MyNestedModel8: Embeddable {
  var id: String
  var nestedName: String
  var notes: [String]?
}
