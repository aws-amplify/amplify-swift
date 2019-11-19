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

    static let noResultInterpretService: CoreMLInterpretServiceErrorString = (
        "Not able to fetch result for interpret text operation",
        "Please try with a different input")

    static let textNotFoundToInterpret: CoreMLInterpretServiceErrorString = (
        "Input text is nil",
        "Text given for interpret could not be found. Check the input")
}
