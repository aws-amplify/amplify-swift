//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct StorageErrorConstants {
    public static let IdentityIdIsEmpty = (
        ErrorDescription: "IdentityId is empty",
        RecoverySuggestion: "IdentityId")

    public static let KeyIsEmpty = (
        ErrorDescription: "KeyIsEmpty",
        RecoverySuggestion: "KeyIsEmpty")

    public static let ExpiresIsInvalid = (
        ErrorDescription: "ExpiresIsInvalid",
        RecoverySuggestion: "ExpiresIsInvalid")

    public static let PrefixIsEmpty = (
        ErrorDescription: "The path is empty",
        RecoverySuggestion: "PrefixIsEmpty")

    public static let LimitIsInvalid = (
        ErrorDescription: "The limit is invalid",
        RecoverySuggestion: "LimitIsInvalid")

    public static let ContentTypeIsEmpty = (
        ErrorDescription: "ContentType is empty",
        RecoverySuggestion: "ContentTypeIsEmpty")

    public static let KeyNotFound = (
        ErrorDescription: "key not found",
        RecoverySuggestion: "key not found")

    public static let PrivateWithTarget = (
        ErrorDescription: "Cannot perform this action on a target for private access level",
        RecoverySuggestion: "")

    public static let MissingFile = (
        ErrorDescription: "The file is missing",
        RecoverySuggestion: "")

    public static let AccessDenied = (
        ErrorDescription: "Access denied!",
        RecoverySuggestion: "")
}
