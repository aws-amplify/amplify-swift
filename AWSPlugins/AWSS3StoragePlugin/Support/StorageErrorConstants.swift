//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct StorageErrorConstants {
    static let IdentityIdIsEmpty = (
        ErrorDescription: "IdentityId is empty",
        RecoverySuggestion: "IdentityId")

    static let KeyIsEmpty = (
        ErrorDescription: "KeyIsEmpty",
        RecoverySuggestion: "KeyIsEmpty")

    static let ExpiresIsInvalid = (
        ErrorDescription: "ExpiresIsInvalid",
        RecoverySuggestion: "ExpiresIsInvalid")

    static let PrefixIsEmpty = (
        ErrorDescription: "The path is empty",
        RecoverySuggestion: "PrefixIsEmpty")

    static let LimitIsInvalid = (
        ErrorDescription: "The limit is invalid",
        RecoverySuggestion: "LimitIsInvalid")

    static let ContentTypeIsEmpty = (
        ErrorDescription: "ContentType is empty",
        RecoverySuggestion: "ContentTypeIsEmpty")

}
