//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSLocation
import AWSClientRuntime

protocol GeoErrorConvertible {
    var fallbackDescription: String { get }
    var geoError: Geo.Error { get }
}

extension AWSLocation.AccessDeniedException: GeoErrorConvertible {
    var fallbackDescription: String { "" }

    var geoError: Geo.Error {
        .accessDenied(
            properties.message ?? fallbackDescription,
            GeoPluginErrorConstants.accessDenied,
            self
        )
    }
}

extension AWSLocation.InternalServerException: GeoErrorConvertible {
    var fallbackDescription: String { "" }

    var geoError: Geo.Error {
        .serviceError(
            properties.message ?? fallbackDescription,
            GeoPluginErrorConstants.internalServer,
            self
        )
    }
}

extension AWSLocation.ResourceNotFoundException: GeoErrorConvertible {
    var fallbackDescription: String { "" }

    var geoError: Geo.Error {
        .serviceError(
            properties.message ?? fallbackDescription,
            GeoPluginErrorConstants.resourceNotFound,
            self
        )
    }
}

extension AWSLocation.ThrottlingException: GeoErrorConvertible {
    var fallbackDescription: String { "" }

    var geoError: Geo.Error {
        .serviceError(
            properties.message ?? fallbackDescription,
            GeoPluginErrorConstants.throttling,
            self
        )
    }
}

extension AWSLocation.ValidationException: GeoErrorConvertible {
    var fallbackDescription: String { "" }

    var geoError: Geo.Error {
        .serviceError(
            properties.message ?? fallbackDescription,
            GeoPluginErrorConstants.validation,
            self
        )
    }
}

extension AWSClientRuntime.UnknownAWSHTTPServiceError: GeoErrorConvertible {
    var fallbackDescription: String { "" }

    var authError: AuthError {
        .unknown(
            """
            Unknown service error occured with:
            - status: \(httpResponse.statusCode)
            - message: \(message ?? fallbackDescription)
            """,
            self
        )
    }
}


class GeoErrorHelper {
    static func getDefaultError(_ error: Error) -> Geo.Error {
        return Geo.Error.unknown(error.localizedDescription, "See underlying error.", error)
    }
}
