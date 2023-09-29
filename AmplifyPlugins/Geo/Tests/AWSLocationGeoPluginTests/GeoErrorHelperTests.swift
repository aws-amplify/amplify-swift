//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSClientRuntime
@testable import AWSLocation
@testable import Amplify
@testable import AWSLocationGeoPlugin
import XCTest

class GeoErrorHelperTests: AWSLocationGeoPluginTestBase {
    /// - Given: a generic error
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the generic error
    /// - Then: a default Geo.Error.unknown is returned
    func testGeoErrorHelperMapsDefaultError() {
        let error = GeoErrorHelper.mapAWSLocationError(GenericError.validation)
        switch error {
            case .unknown(_, _, _):
                break
            default:
            XCTFail("Failed to map to default error")
        }
    }
    
    /// - Given: SearchPlaceIndexForTextOutputError of access denied
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForTextOutputError
    /// - Then: a default Geo.Error.accessDenied is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForTextOutputErrorAccessDenied() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForTextOutputError.accessDeniedException(AccessDeniedException()))
        switch error {
            case .accessDenied(_, _, _):
                break
            default:
                XCTFail("Failed to map to default error")
        }
    }
    
    /// - Given: SearchPlaceIndexForTextOutputError of internal server
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForTextOutputError
    /// - Then: a default Geo.Error.serviceError is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForTextOutputErrorInternalServer() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForTextOutputError.internalServerException(InternalServerException()))
        switch error {
            case .serviceError(_, _, _):
                break
            default:
                XCTFail("Failed to map to default error")
        }
    }
    
    /// - Given: SearchPlaceIndexForTextOutputError of resource not found
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForTextOutputError
    /// - Then: a default Geo.Error.serviceError is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForTextOutputErrorResourceNotFound() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForTextOutputError.resourceNotFoundException(ResourceNotFoundException()))
        switch error {
            case .serviceError(_, _, _):
                break
            default:
                XCTFail("Failed to map to service error")
        }
    }
    
    /// - Given: SearchPlaceIndexForTextOutputError of throttling
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForTextOutputError
    /// - Then: a default Geo.Error.serviceError is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForTextOutputErrorThrottling() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForTextOutputError.throttlingException(ThrottlingException()))
        switch error {
            case .serviceError(_, _, _):
                break
            default:
                XCTFail("Failed to map to service error")
        }
    }

    /// - Given: SearchPlaceIndexForTextOutputError of validation
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForTextOutputError
    /// - Then: a default Geo.Error.serviceError is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForTextOutputErrorValidation() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForTextOutputError.validationException(ValidationException()))
        switch error {
            case .serviceError(_, _, _):
                break
            default:
                XCTFail("Failed to map to service error")
        }
    }
    
    /// - Given: SearchPlaceIndexForTextOutputError of unknown
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForTextOutputError
    /// - Then: a default Geo.Error.unknown is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForTextOutputErrorUnknown() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForTextOutputError.unknown(UnknownAWSHttpServiceError()))
        switch error {
            case .unknown(_, _, _):
                break
            default:
                XCTFail("Failed to map to unknown error")
        }
    }
    
    /// - Given: SearchPlaceIndexForPositionOutputError of access denied
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForPositionOutputError
    /// - Then: a default Geo.Error.accessDenied is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForPositionOutputErrorAccessDenied() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForPositionOutputError.accessDeniedException(AccessDeniedException()))
        switch error {
            case .accessDenied(_, _, _):
                break
            default:
                XCTFail("Failed to map to default error")
        }
    }
    
    /// - Given: SearchPlaceIndexForPositionOutputError of internal server
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForPositionOutputError
    /// - Then: a default Geo.Error.serviceError is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForPositionOutputErrorInternalServer() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForPositionOutputError.internalServerException(InternalServerException()))
        switch error {
            case .serviceError(_, _, _):
                break
            default:
                XCTFail("Failed to map to default error")
        }
    }
    
    /// - Given: SearchPlaceIndexForPositionOutputError of resource not found
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForPositionOutputError
    /// - Then: a default Geo.Error.serviceError is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForPositionOutputErrorErrorResourceNotFound() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForPositionOutputError.resourceNotFoundException(ResourceNotFoundException()))
        switch error {
            case .serviceError(_, _, _):
                break
            default:
                XCTFail("Failed to map to service error")
        }
    }
    
    /// - Given: SearchPlaceIndexForPositionOutputError of throttling
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForPositionOutputError
    /// - Then: a default Geo.Error.serviceError is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForPositionOutputErrorThrottling() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForPositionOutputError.throttlingException(ThrottlingException()))
        switch error {
            case .serviceError(_, _, _):
                break
            default:
                XCTFail("Failed to map to service error")
        }
    }

    /// - Given: SearchPlaceIndexForPositionOutputError of validation
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForPositionOutputError
    /// - Then: a default Geo.Error.serviceError is returned
    func testGeoErrorHelperMapsSearchPlaceIndexForPositionOutputErrorValidation() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForPositionOutputError.validationException(ValidationException()))
        switch error {
            case .serviceError(_, _, _):
                break
            default:
                XCTFail("Failed to map to service error")
        }
    }
    
    /// - Given: SearchPlaceIndexForPositionOutputError of unknown
    /// - When: GeoErrorHelper.mapAWSLocationError is called with the SearchPlaceIndexForPositionOutputError
    /// - Then: a default Geo.Error.unknown is returned
    func testGeoErrorHelperMapsSSearchPlaceIndexForPositionOutputErrorUnknown() {
        let error = GeoErrorHelper.mapAWSLocationError(SearchPlaceIndexForPositionOutputError.unknown(UnknownAWSHttpServiceError()))
        switch error {
            case .unknown(_, _, _):
                break
            default:
                XCTFail("Failed to map to unknown error")
        }
    }
}

enum GenericError: Error {
    case validation
}
