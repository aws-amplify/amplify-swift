//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

import AWSLocation

class GeoErrorHelper {
    static func getDefaultError(_ error: Error) -> Geo.Error {
        return Geo.Error.unknown(error.localizedDescription, "See underlying error.", error)
    }

    static func mapAWSLocationError(_ error: Error) -> Geo.Error {
        let defaultError = GeoErrorHelper.getDefaultError(error)

        if let searchPlaceIndexForTextOutputError = error as? SearchPlaceIndexForTextOutputError {
            return GeoErrorHelper.mapError(error: searchPlaceIndexForTextOutputError) ?? defaultError
        } else if let searchPlaceIndexForPositionOutputError = error as? SearchPlaceIndexForPositionOutputError {
            return GeoErrorHelper.mapError(error: searchPlaceIndexForPositionOutputError) ?? defaultError
        }

        return defaultError
    }

    static func mapError(error: SearchPlaceIndexForTextOutputError) -> Geo.Error? {
        switch error {
        case .accessDeniedException(let accessDeniedException):
            return Geo.Error.accessDenied(accessDeniedException.message ?? "", GeoPluginErrorConstants.accessDenied, error)
        case .internalServerException(let internalServerException):
            return Geo.Error.serviceError(internalServerException.message ?? "", GeoPluginErrorConstants.internalServer, error)
        case .resourceNotFoundException(let resournceNotFoundException):
            return Geo.Error.serviceError(resournceNotFoundException.message ?? "", GeoPluginErrorConstants.resourceNotFound, error)
        case .throttlingException(let throttlingException):
            return Geo.Error.serviceError(throttlingException.message ?? "", GeoPluginErrorConstants.throttling, error)
        case .validationException(let validationException):
            return Geo.Error.serviceError(validationException.message ?? "", GeoPluginErrorConstants.validation, error)
        case .unknown(let unknownAWSHttpServiceError):
            return Geo.Error.unknown(unknownAWSHttpServiceError._message ?? "", "See underlying error.", error)
        }
    }

    static func mapError(error: SearchPlaceIndexForPositionOutputError) -> Geo.Error? {
        switch error {
        case .accessDeniedException(let accessDeniedException):
            return Geo.Error.accessDenied(accessDeniedException.message ?? "", GeoPluginErrorConstants.accessDenied, error)
        case .internalServerException(let internalServerException):
            return Geo.Error.serviceError(internalServerException.message ?? "", GeoPluginErrorConstants.internalServer, error)
        case .resourceNotFoundException(let resournceNotFoundException):
            return Geo.Error.serviceError(resournceNotFoundException.message ?? "", GeoPluginErrorConstants.resourceNotFound, error)
        case .throttlingException(let throttlingException):
            return Geo.Error.serviceError(throttlingException.message ?? "", GeoPluginErrorConstants.throttling, error)
        case .validationException(let validationException):
            return Geo.Error.serviceError(validationException.message ?? "", GeoPluginErrorConstants.validation, error)
        case .unknown(let unknownAWSHttpServiceError):
            return Geo.Error.unknown(unknownAWSHttpServiceError._message ?? "", "See underlying error.", error)
        }
    }
}
