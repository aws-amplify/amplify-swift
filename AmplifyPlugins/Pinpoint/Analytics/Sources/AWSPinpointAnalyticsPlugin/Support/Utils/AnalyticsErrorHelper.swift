//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import ClientRuntime
import Foundation

class AnalyticsErrorHelper {
    static func getDefaultError(_ error: Error) -> AnalyticsError {
        if let sdkError = error as? SdkError<PutEventsOutputError>{
            return sdkError.analyticsError
        }

        if let analyticsError = error as? AnalyticsError {
            return analyticsError
        }

        return getDefaultError(error as NSError)
    }

    static func getDefaultError(_ error: NSError) -> AnalyticsError {
        let errorMessage = """
        Domain: [\(error.domain)
        Code: [\(error.code)
        LocalizedDescription: [\(error.localizedDescription)
        LocalizedFailureReason: [\(error.localizedFailureReason ?? "")
        LocalizedRecoverySuggestion: [\(error.localizedRecoverySuggestion ?? "")
        """

        return AnalyticsError.unknown(errorMessage, error)
    }
}
