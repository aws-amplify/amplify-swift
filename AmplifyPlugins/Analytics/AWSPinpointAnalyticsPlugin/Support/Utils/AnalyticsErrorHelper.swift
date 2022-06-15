//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class AnalyticsErrorHelper {
  static func getDefaultError(_ error: Error) -> AnalyticsError {
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

    return AnalyticsError.unknown(errorMessage)
  }
}
