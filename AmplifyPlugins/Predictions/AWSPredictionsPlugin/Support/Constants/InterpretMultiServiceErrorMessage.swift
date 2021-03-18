//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

typealias InterpretMultiServiceErrorString = (errorDescription: ErrorDescription,
    recoverySuggestion: RecoverySuggestion)

struct InterpretMultiServiceErrorMessage {
    static let accessDenied: InterpretMultiServiceErrorString = (
        "Access denied",
        "")

    static let onlineInterpretServiceNotAvailable: InterpretMultiServiceErrorString = (
        "Online interpret service is not available",
        "Please check if the values are proprely initialized")

    static let offlineInterpretServiceNotAvailable: InterpretMultiServiceErrorString = (
        "Offline interpret service is not available",
        "Please check if the values are proprely initialized")

    static let noResultInterpretService: InterpretMultiServiceErrorString = (
        "Not able to fetch result for interpret text operation",
        "Please try with a different input")

    static let textNotFoundToInterpret: InterpretMultiServiceErrorString = (
        "Input text is nil",
        "Text given for interpret could not be found. Check the input")

    static let interpretTextNoResult: InterpretMultiServiceErrorString = (
        "No result found for the text",
        "Interpret text did not produce any result")
}
