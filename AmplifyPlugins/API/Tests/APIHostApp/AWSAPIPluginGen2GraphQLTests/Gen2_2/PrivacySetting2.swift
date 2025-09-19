//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public enum PrivacySetting2: String, EnumPersistable {
  case `private` = "PRIVATE"
  case friendsOnly = "FRIENDS_ONLY"
  case `public` = "PUBLIC"
}
