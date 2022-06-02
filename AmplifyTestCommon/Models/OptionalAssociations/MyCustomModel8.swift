//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct MyCustomModel8: Embeddable {
  var id: String
  var name: String
  var desc: String?
  var children: [MyNestedModel8]?
}
