//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Item types for each row displaying Developer Environment Information
enum EnvironmentInfoItemType {
    case nodejsVersion(String?)
    case npmVersion(String?)
    case amplifyCLIVersion(String?)
    case podVersion(String?)
    case xcodeVersion(String?)
    case osVersion(String?)
}
