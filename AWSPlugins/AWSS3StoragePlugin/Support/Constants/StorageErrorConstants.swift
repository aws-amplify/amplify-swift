//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias StorageErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct StorageErrorConstants {
    static let identityIdIsEmpty: StorageErrorString = (
        "IdentityId is empty",
         "IdentityId")

    static let keyIsEmpty: StorageErrorString = (
        "KeyIsEmpty",
         "KeyIsEmpty")

    static let expiresIsInvalid: StorageErrorString = (
        "ExpiresIsInvalid",
         "ExpiresIsInvalid")

    static let pathIsEmpty: StorageErrorString = (
        "The path is empty",
         "PathIsEmpty")

    static let contentTypeIsEmpty: StorageErrorString = (
        "ContentType is empty",
        "ContentTypeIsEmpty")

    static let keyNotFound: StorageErrorString = (
        "key not found",
        "key not found")

    static let privateWithTarget: StorageErrorString = (
        "Cannot perform this action on a target for private access level",
         "")

    static let missingFile: StorageErrorString = (
        "The file is missing",
         "")

    static let accessDenied: StorageErrorString = (
        "Access denied!",
        "")

    static let metadataKeysInvalid: StorageErrorString = (
        "Metadata keys should all be lowercased",
        "")
}
