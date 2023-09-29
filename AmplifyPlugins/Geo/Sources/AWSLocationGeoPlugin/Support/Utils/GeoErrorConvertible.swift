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
    var geoError: Geo.Error { get }
}

extension AWSLocation.AccessDeniedException: GeoErrorConvertible {
    var geoError: Geo.Error {
        .accessDenied(
            message ?? "",
            GeoPluginErrorConstants.accessDenied,
            self
        )
    }
}

extension AWSLocation.InternalServerException: GeoErrorConvertible {
    var fallbackDescription: String { "" }

    var geoError: Geo.Error {
        .serviceError(
            message ?? "",
            GeoPluginErrorConstants.internalServer,
            self
        )
    }
}

extension AWSLocation.ResourceNotFoundException: GeoErrorConvertible {
    var fallbackDescription: String { "" }

    var geoError: Geo.Error {
        .serviceError(
            message ?? "",
            GeoPluginErrorConstants.resourceNotFound,
            self
        )
    }
}

extension AWSLocation.ThrottlingException: GeoErrorConvertible {
    var fallbackDescription: String { "" }

    var geoError: Geo.Error {
        .serviceError(
            message ?? "",
            GeoPluginErrorConstants.throttling,
            self
        )
    }
}

extension AWSLocation.ValidationException: GeoErrorConvertible {
    var fallbackDescription: String { "" }

    var geoError: Geo.Error {
        .serviceError(
            message ?? "",
            GeoPluginErrorConstants.validation,
            self
        )
    }
}

extension AWSClientRuntime.UnknownAWSHTTPServiceError: GeoErrorConvertible {
    var geoError: Geo.Error {
        .unknown(
            """
            Unknown service error occured with:
            - status: \(httpResponse.statusCode)
            - message: \(message ?? "")
            """,
            "",
            self
        )
    }
}
