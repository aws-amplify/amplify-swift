//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AuthPluginConstants {
    
    /// The time interval  under which the refresh of  UserPool or awsCredentials tokens will happen
    static let sessionRefreshInterval: TimeInterval = 2 * 60
    
}
