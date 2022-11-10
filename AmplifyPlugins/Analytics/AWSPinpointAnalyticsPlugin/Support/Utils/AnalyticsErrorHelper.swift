//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class AnalyticsErrorHelper {
    static func getDefaultError(_ error: NSError) -> AnalyticsError {
        if error.isConnectivityError {
            return .unknown(
                AnalyticsPluginErrorConstant.deviceOffline.errorDescription,
                error
            )
        }

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

private extension NSError {
    private static let networkErrorCodes = [
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorNotConnectedToInternet
    ]

    var isConnectivityError: Bool {
        return Self.networkErrorCodes.contains(where: { $0 == code })
    }
}
