//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

typealias IdentifyMultiServiceErrorString = (errorDescription: ErrorDescription,
                                             recoverySuggestion: RecoverySuggestion)

struct IdentifyMultiServiceErrorMessage {
    static let onlineIdentifyServiceNotAvailable: IdentifyMultiServiceErrorString = (
        "Online identify service is not available",
        "Please check if the values are proprely initialized"
    )

    static let offlineIdentifyServiceNotAvailable: IdentifyMultiServiceErrorString = (
        "Offline identify service is not available",
        "Please check if the values are proprely initialized"
    )

    static let noResultIdentifyService: IdentifyMultiServiceErrorString = (
        "Not able to fetch result for identify operation",
        "Please try with a different input"
    )
}
