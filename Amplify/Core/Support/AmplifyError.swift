//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Convenience typealias to disambiguate positional parameters of AmplifyErrors
public typealias ErrorDescription = String

/// Convenience typealias to disambiguate positional parameters of AmplifyErrors
public typealias RecoverySuggestion = String

public typealias ErrorName = String
public typealias Field = String
public typealias Key = String
public typealias TargetIdentityId = String

/// Amplify's philosophy is to expose friendly error messages to the customer that assist with debugging.
/// Therefore, failable APIs are declared to return error results with Amplify errors, which require
/// recovery suggestions and error messages.
public protocol AmplifyError: LocalizedError {
    /// A localized message describing what error occurred.
    var errorDescription: ErrorDescription { get }

    /// A localized message describing how one might recover from the failure.
    var recoverySuggestion: RecoverySuggestion { get }
}
