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

        if error.domain == NSURLErrorDomain {
            return Geo.Error.networkError(error.localizedDescription, "See underlying error.", error)
        } else {
            return Geo.Error.unknown(error.localizedDescription, "See underlying error.", error)
        }
    }

    static func mapAWSLocationError(_ error: Error) -> Geo.Error {
        let error = error as NSError
        let defaultError = GeoErrorHelper.getDefaultError(error)

        guard error.domain == AWSLocationErrorDomain else {
            return defaultError
        }

        let errorTypeOptional = AWSLocationErrorType.init(rawValue: error.code)
        guard let errorType = errorTypeOptional else {
            return defaultError
        }

        return GeoErrorHelper.mapError(description: error.localizedDescription,
                                       type: errorType,
                                       error: error) ?? defaultError
    }

    static func mapError(description: ErrorDescription, type: AWSLocationErrorType, error: Error) -> Geo.Error? {
        switch type {
        case .accessDenied:
            return Geo.Error.accessDenied(description, GeoPluginErrorConstants.accessDenied, error)
        case .conflict:
            return Geo.Error.accessDenied(description, GeoPluginErrorConstants.conflict, error)
        case .internalServer:
            return Geo.Error.serviceError(description, GeoPluginErrorConstants.internalServer, error)
        case .resourceNotFound:
            return Geo.Error.serviceError(description, GeoPluginErrorConstants.resourceNotFound, error)
        case .serviceQuotaExceeded:
            return Geo.Error.serviceError(description, GeoPluginErrorConstants.serviceQuotaExceeded, error)
        case .throttling:
            return Geo.Error.serviceError(description, GeoPluginErrorConstants.throttling, error)
        case .validation:
            return Geo.Error.serviceError(description, GeoPluginErrorConstants.validation, error)
        case .unknown:
            break
        @unknown default:
            break
        }
        return nil
    }
}
