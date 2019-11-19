//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

typealias CoreMLInterpretServiceErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct CoreMLInterpretErrorMessage {
    static let accessDenied: CoreMLInterpretServiceErrorString = (
        "Access denied!",
        "")

    static let noLanguageFound: CoreMLInterpretServiceErrorString = (
        "No result was found for language. An unknown error occurred.",
        "Please try with different input")

    static let dominantLanguageNotDetermined: CoreMLInterpretServiceErrorString = (
        "Could not determine the predominant language in the text",
        "Please try with different input")

    static let onlineInterpretServiceNotAvailable: CoreMLInterpretServiceErrorString = (
        "Online interpret service is not available",
        "Please check if the values are proprely initialized")

    static let offlineInterpretServiceNotAvailable: CoreMLInterpretServiceErrorString = (
        "Offline interpret service is not available",
        "Please check if the values are proprely initialized")

    static let noResultInterpretService: CoreMLInterpretServiceErrorString = (
        "Not able to fetch result for interpret text operation",
        "Please try with a different input")

    static let textNotFoundToInterpret: CoreMLInterpretServiceErrorString = (
    "Input text is nil",
    "Text given for interpret could not be found. Please check the input")
}

