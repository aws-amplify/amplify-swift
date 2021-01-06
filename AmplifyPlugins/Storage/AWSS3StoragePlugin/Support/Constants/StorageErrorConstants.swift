//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias StorageValidationErrorString = (field: Field,
    errorDescription: ErrorDescription,
    recoverySuggestion: RecoverySuggestion)
typealias StorageServiceErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct StorageErrorConstants {

    static let identityIdIsEmpty: StorageValidationErrorString = (
        "targetIdentityId",
        "The `targetIdentityId` is specified but is empty.",
        "Specify a non-empty identityId of the target user you wish to use.")

    static let keyIsEmpty: StorageValidationErrorString = (
        "key",
        "The `key` is specified but is empty.",
        "Specify a non-empty key.")

    static let expiresIsInvalid: StorageValidationErrorString = (
        "expire",
        "The `expire` field is out of range.",
        "Specify a positive expire time in seconds like 3600 for an one hour expiry time.")

    static let pathIsEmpty: StorageValidationErrorString = (
        "path",
        "The `path` is specified but is empty.",
        "Specify a non-empty path")

    // TODO content type messaging
    static let contentTypeIsEmpty: StorageValidationErrorString = (
        "contentType",
        "The `contentType` is specified but is empty.",
        """
        Either do not specify a contentType and it will default to TODO or specify a correct MIME type like X, Y, Z
        representing the type of the object you are uploading. For more information, please see X
        """)

    static let invalidAccessLevelWithTarget: StorageValidationErrorString = (
        "accessLevel",
        "An `accessLevel` specified as public or private cannot be used with `targetIdentityId`",
        """
        An action can only be performed on a target user by specifying the `targetIdentityId` with an accessLevel of
        protected. Perform an action on your own user with private `accessLevel` by removing the
        `targetIdentityId` or change the `accessLevel` to protected and specify the target user to perform the action.
        """)

    static let localFileNotFound: StorageValidationErrorString = (
        "local",
        "The file located at the `local` URL is missing",
        "Make sure the file exists before uploading to storage.")

    static let metadataKeysInvalid: StorageValidationErrorString = (
        "metadata",
        "The keys in `metadata` dictionary is invalid.",
        "The values of the keys can only be lowercased.")

    static let accessDenied: StorageServiceErrorString = (
        "Access denied!",
        "")
}
