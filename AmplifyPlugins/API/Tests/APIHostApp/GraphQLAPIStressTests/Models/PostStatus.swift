//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public enum PostStatus: String, EnumPersistable {
  case active = "ACTIVE"
  case inactive = "INACTIVE"
}
