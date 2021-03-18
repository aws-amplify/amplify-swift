//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

typealias ConvertMultiServiceErrorString = (errorDescription: ErrorDescription,
    recoverySuggestion: RecoverySuggestion)

struct ConvertMultiServiceErrorMessage {
    static let accessDenied: ConvertMultiServiceErrorString = (
        "Access denied",
        "")

    static let onlineConvertServiceNotAvailable: ConvertMultiServiceErrorString = (
        "Online interpret service is not available",
        "Please check if the values are proprely initialized")

    static let offlineConvertServiceNotAvailable: ConvertMultiServiceErrorString = (
        "Offline interpret service is not available",
        "Please check if the values are proprely initialized")

    static let noResultConvertService: ConvertMultiServiceErrorString = (
        "Not able to fetch result for convert operation",
        "Please try with a different input")

    static let inputNotFoundToConvert: ConvertMultiServiceErrorString = (
        "Input is nil",
        "Text given for interpret could not be found. Check the input")

    static let convertTextNoResult: ConvertMultiServiceErrorString = (
        "No result found for the text or audio",
        "Convert text or audio did not produce any result")
}
