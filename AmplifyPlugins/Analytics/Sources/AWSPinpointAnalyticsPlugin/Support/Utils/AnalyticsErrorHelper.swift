//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AwsCommonRuntimeKit

enum AnalyticsErrorHelper {
    static func getDefaultError(_ error: Error) -> AnalyticsError {
        switch error {
        case let error as AnalyticsErrorConvertible:
            return error.analyticsError
        default:
            return getDefaultError(error as NSError)
        }
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
