//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias StorageErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

// TODO: lowercase, enum
struct StorageErrorConstants {
    static let IdentityIdIsEmpty: StorageErrorString = (
        "IdentityId is empty",
         "IdentityId")

    static let KeyIsEmpty: StorageErrorString = (
        "KeyIsEmpty",
         "KeyIsEmpty")

    static let ExpiresIsInvalid: StorageErrorString = (
        "ExpiresIsInvalid",
         "ExpiresIsInvalid")

    static let PathIsEmpty: StorageErrorString = (
        "The path is empty",
         "PathIsEmpty")

    static let ContentTypeIsEmpty: StorageErrorString = (
        "ContentType is empty",
        "ContentTypeIsEmpty")

    static let KeyNotFound: StorageErrorString = (
        "key not found",
        "key not found")

    static let PrivateWithTarget: StorageErrorString = (
        "Cannot perform this action on a target for private access level",
         "")

    static let MissingFile: StorageErrorString = (
        "The file is missing",
         "")

    static let AccessDenied: StorageErrorString = (
        "Access denied!",
        "")

    static let MetadataKeysInvalid: StorageErrorString = (
        "Metadata keys should all be lowercased",
        "")
}
