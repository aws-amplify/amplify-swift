//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Defines the auth session behavior
public protocol AuthSession {

    /// Indicates whether a user is signed in or not
    ///
    /// `true` if a user is signed in
    var isSignedIn: Bool { get }
}
