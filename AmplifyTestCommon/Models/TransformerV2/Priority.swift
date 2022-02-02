//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public enum Priority: String, EnumPersistable {
  case low = "LOW"
  case normal = "NORMAL"
  case high = "HIGH"
}
