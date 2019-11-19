//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

typealias InterpretMultiServiceErrorString = (errorDescription: ErrorDescription,
    recoverySuggestion: RecoverySuggestion)

struct InterpretMultiServiceErrorMessage {
    static let accessDenied: InterpretMultiServiceErrorString = (
        "Access denied!",
        "")

    static let onlineInterpretServiceNotAvailable: InterpretMultiServiceErrorString = (
        "Online interpret service is not available",
        "Please check if the values are proprely initialized")

    static let offlineInterpretServiceNotAvailable: InterpretMultiServiceErrorString = (
        "Offline interpret service is not available",
        "Please check if the values are proprely initialized")

    static let textNotFoundToInterpret: InterpretMultiServiceErrorString = (
        "Input text is nil",
        "Text given for interpret could not be found. Please check the input")
}
