//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
#if COCOAPODS
import AWSLocation
#else
import AWSLocationXCF
#endif

class GeoErrorHelper {
    static func getDefaultError(_ error: Error) -> Geo.Error {
        let error = error as NSError
        let errorMessage = """
        Domain: [\(error.domain)]
        Code: [\(error.code)]
        LocalizedDescription: [\(error.localizedDescription)]
        LocalizedFailureReason: [\(error.localizedFailureReason ?? "")]
        LocalizedRecoverySuggestion: [\(error.localizedRecoverySuggestion ?? "")]
        """

        return Geo.Error.unknown(errorMessage, "")
    }

    static func mapAWSLocationError(_ error: Error) -> Geo.Error {
        let error = error as NSError
        let defaultError = GeoErrorHelper.getDefaultError(error)

        print(defaultError)

        guard error.domain == AWSLocationErrorDomain else {
            return defaultError
        }

        let errorTypeOptional = AWSLocationErrorType.init(rawValue: error.code)
        guard let errorType = errorTypeOptional else {
            return defaultError
        }

        return GeoErrorHelper.mapError(description: error.localizedDescription, type: errorType) ?? defaultError
    }

    static func mapError(description: ErrorDescription, type: AWSLocationErrorType) -> Geo.Error? {
        switch type {
        case .accessDenied:
            return Geo.Error.accessDenied(description, GeoPluginErrorConstants.accessDenied)
        case .conflict:
            break
        case .internalServer:
            break
        case .resourceNotFound:
            break
        case .serviceQuotaExceeded:
            break
        case .throttling:
            break
        case .validation:
            break
        case .unknown:
            break
        @unknown default:
            break
        }
        return nil
    }
}
