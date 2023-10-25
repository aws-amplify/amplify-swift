//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore


struct AWSLocationClientConfiguration {
    let region: String
    let credentialsProvider: CredentialsProvider
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    static let servicName = "Location"
    static let clientName = "LocationClient"
    let signingName = "geo"
}

struct EndpointParameters {
    let endpoint: String
    let region: String
}

// https://geo.<region>.amazonaws.com/<>/<version>/

struct EndpointResolver {

}

struct HTTPMethod {
    let verb: String
    static let get = Self(verb: "GET")
    static let post = Self(verb: "POST")
    static let put = Self(verb: "PUT")
    static let delete = Self(verb: "DELETE")
}

struct PlaceholderError: Error {}

struct Action {
    let name: String
    let method: HTTPMethod
    let requestURI: String
    let successCode: Int
    let hostPrefix: String
    let mapError: (Data, HTTPURLResponse) throws -> Error

    func url(region: String) throws -> URL {
        guard let url = URL(
            string: "https://\(hostPrefix)geo.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }

    func request(region: String) throws -> URLRequest {
        let url = try url(region: region)
        var request = URLRequest(url: url)
        request.httpMethod = method.verb
        return request
    }
}

// Placeholder Error
struct ServiceError: Error {
    let message: String?
    let type: String?
    let httpURLResponse: HTTPURLResponse
}

extension Action {

    /*
    "SearchPlaceIndexForText":{
       "name":"SearchPlaceIndexForText",
       "http":{
         "method":"POST",
         "requestUri":"/places/v0/indexes/{IndexName}/search/text",
         "responseCode":200
       },
       "input":{"shape":"SearchPlaceIndexForTextRequest"},
       "output":{"shape":"SearchPlaceIndexForTextResponse"},
       "errors":[
         {"shape":"InternalServerException"},
         {"shape":"ResourceNotFoundException"},
         {"shape":"AccessDeniedException"},
         {"shape":"ValidationException"},
         {"shape":"ThrottlingException"}
       ],
       "endpoint":{"hostPrefix":"places."}
     }
     */
    static func searchPlaceIndexForText(indexName: String) -> Action {
        Action(
            name: "SearchPlaceIndexForText",
            method: .post,
            requestURI: "/places/v0/indexes/\(indexName)/search/text",
            successCode: 200,
            hostPrefix: "places.",
            mapError: { data, response in
                let error = try RestJSONError(data: data, response: response)
                switch error.type {
                case "AccessDeniedException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "InternalServerException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ResourceNotFoundException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ThrottlingException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ValidationException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                default:
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                }
            }
        )
    }

    /*
     "SearchPlaceIndexForPosition":{
       "name":"SearchPlaceIndexForPosition",
       "http":{
         "method":"POST",
         "requestUri":"/places/v0/indexes/{IndexName}/search/position",
         "responseCode":200
       },
       "input":{"shape":"SearchPlaceIndexForPositionRequest"},
       "output":{"shape":"SearchPlaceIndexForPositionResponse"},
       "errors":[
         {"shape":"InternalServerException"},
         {"shape":"ResourceNotFoundException"},
         {"shape":"AccessDeniedException"},
         {"shape":"ValidationException"},
         {"shape":"ThrottlingException"}
       ],
       "endpoint":{"hostPrefix":"places."}
     }
     */
    static func searchPlaceIndexForPosition(indexName: String) -> Action {
        Action(
            name: "SearchPlaceIndexForPosition",
            method: .post,
            requestURI: "/places/v0/indexes/\(indexName)/search/position",
            successCode: 200,
            hostPrefix: "places.",
            mapError: { data, response in
                let error = try RestJSONError(data: data, response: response)
                switch error.type {
                case "AccessDeniedException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "InternalServerException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ResourceNotFoundException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ThrottlingException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ValidationException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                default:
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                }
            }
        )
    }
}

struct RestJSONErrorPayload: Decodable {
    // TODO: Use a custom decoder here
    let code: String?
    let __type: String?

    let message: String?
    let Message: String?
    let errorMessage: String?

    var resolvedErrorType: String? {
        code ?? __type
    }

    var resolvedErrorMessage: String? {
        message ?? Message ?? errorMessage
    }
}

struct RestJSONError {
    let message: String?
    let type: String?

    init(data: Data, response: HTTPURLResponse) throws {
        let errorMessage = response.value(
            forHTTPHeaderField: "x-amzn-error-message"
        ) ?? response.value(
            forHTTPHeaderField: ":error-message"
        ) ?? response.value(
            forHTTPHeaderField: "x-amzn-ErrorMessage"
        )

        let errorType = response.value(
            forHTTPHeaderField: "X-Amzn-Errortype"
        )

        let errorPayload = try JSONDecoder().decode(
            RestJSONErrorPayload.self,
            from: data
        )

        self.message = (errorMessage ?? errorPayload.resolvedErrorMessage)
            .map { $0.substringAfter("#").substringBefore(":").trim() }
        self.type = errorType ?? errorPayload.resolvedErrorType
    }
}

class LocationClient {
    let configuration: AWSLocationClientConfiguration

    /*
     - encoder
     - decoder
     --- HTTPMethod
     - serviceName
     --- Operation
     --- idempotencyToken / - idempotencyTokenGenerator
     - logger
     - partitionID
     - credentialsProvider
     - region
     - signingName ("geo")
     - signingRegion
     */

    init(configuration: AWSLocationClientConfiguration) {
        self.configuration = configuration
    }

    /*
     - build endpoint url
     - add headers:
        - user-agent: ...
        - Content-Type: application/json header
        - Signing Headers:
            - Host: ...
            - X-Amz-Date: ...
            - X-Amz-Security-Token: ...
            - Authorization: ...
        - Content-Length: <String(body.count)>
     - Add query items (if necessary)
     - Encode request body
     - Setup retry mechanism
     - sigv4 signing
     - make request
     - check for success status code
        - if failure: map to applicable error type
        - if success: decode responseData to expected response type
     */

    func searchPlaceIndexForText(input: SearchPlaceIndexForTextInput) async throws -> SearchPlaceIndexForTextOutputResponse {
        let requestData = try configuration.encoder.encode(input)
        let action = Action.searchPlaceIndexForText(
            indexName: "<index_name>"
        )

        let url = try action.url(region: configuration.region)
        let credentials = try await configuration.credentialsProvider.fetchCredentials()
        let userAgent = "" // TODO: generate user-agent

        let signer = SigV4Signer(
            credentials: credentials,
            serviceName: configuration.signingName,
            region: configuration.region
        )

        let signedRequest = signer.sign(
            url: url,
            method: .post,
            body: .data(requestData),
            headers: [
                "Content-Type": "application/json",
                "User-Agent": userAgent,
                "Content-Length": String(requestData.count)
            ]
        )


        let (responseData, urlResponse) = try await URLSession.shared.upload(
            for: signedRequest,
            from: requestData
        )

        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            throw PlaceholderError() // this shouldn't happen
        }

        guard (200..<300).contains(httpURLResponse.statusCode) else {
            throw try action.mapError(responseData, httpURLResponse)
        }

        let response = try configuration.decoder.decode(
            SearchPlaceIndexForTextOutputResponse.self,
            from: responseData
        )

        return response
    }

    func searchPlaceIndexForPosition(input: SearchPlaceIndexForPositionInput) async throws -> SearchPlaceIndexForPositionOutputResponse {
        fatalError()
    }
}


struct SearchPlaceIndexForTextInput: Equatable, Encodable {
    /// An optional parameter that indicates a preference for places that are closer to a specified position. If provided, this parameter must contain a pair of numbers. The first number represents the X coordinate, or longitude; the second number represents the Y coordinate, or latitude. For example, [-123.1174, 49.2847] represents the position with longitude -123.1174 and latitude 49.2847. BiasPosition and FilterBBox are mutually exclusive. Specifying both options results in an error.
    var biasPosition: [Swift.Double]?
    /// An optional parameter that limits the search results by returning only places that are within the provided bounding box. If provided, this parameter must contain a total of four consecutive numbers in two pairs. The first pair of numbers represents the X and Y coordinates (longitude and latitude, respectively) of the southwest corner of the bounding box; the second pair of numbers represents the X and Y coordinates (longitude and latitude, respectively) of the northeast corner of the bounding box. For example, [-12.7935, -37.4835, -12.0684, -36.9542] represents a bounding box where the southwest corner has longitude -12.7935 and latitude -37.4835, and the northeast corner has longitude -12.0684 and latitude -36.9542. FilterBBox and BiasPosition are mutually exclusive. Specifying both options results in an error.
    var filterBBox: [Swift.Double]?
    /// A list of one or more Amazon Location categories to filter the returned places. If you include more than one category, the results will include results that match any of the categories listed. For more information about using categories, including a list of Amazon Location categories, see [Categories and filtering](https://docs.aws.amazon.com/location/latest/developerguide/category-filtering.html), in the Amazon Location Service Developer Guide.
    var filterCategories: [Swift.String]?
    /// An optional parameter that limits the search results by returning only places that are in a specified list of countries.
    ///
    /// * Valid values include [ISO 3166](https://www.iso.org/iso-3166-country-codes.html) 3-digit country codes. For example, Australia uses three upper-case characters: AUS.
    var filterCountries: [Swift.String]?
    /// The name of the place index resource you want to use for the search.
    /// This member is required.
    var indexName: Swift.String?
    /// The optional [API key](https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html) to authorize the request.
    var key: Swift.String?
    /// The preferred language used to return results. The value must be a valid [BCP 47](https://tools.ietf.org/search/bcp47) language tag, for example, en for English. This setting affects the languages used in the results, but not the results themselves. If no language is specified, or not supported for a particular result, the partner automatically chooses a language for the result. For an example, we'll use the Greek language. You search for Athens, Greece, with the language parameter set to en. The result found will most likely be returned as Athens. If you set the language parameter to el, for Greek, then the result found will more likely be returned as Αθήνα. If the data provider does not have a value for Greek, the result will be in a language that the provider does support.
    var language: Swift.String?
    /// An optional parameter. The maximum number of results returned per request. The default: 50
    var maxResults: Swift.Int
    /// The address, name, city, or region to be used in the search in free-form text format. For example, 123 Any Street.
    /// This member is required.
    var text: Swift.String?

    init(
        biasPosition: [Swift.Double]? = nil,
        filterBBox: [Swift.Double]? = nil,
        filterCategories: [Swift.String]? = nil,
        filterCountries: [Swift.String]? = nil,
        indexName: Swift.String? = nil,
        key: Swift.String? = nil,
        language: Swift.String? = nil,
        maxResults: Swift.Int = 0,
        text: Swift.String? = nil
    )
    {
        self.biasPosition = biasPosition
        self.filterBBox = filterBBox
        self.filterCategories = filterCategories
        self.filterCountries = filterCountries
        self.indexName = indexName
        self.key = key
        self.language = language
        self.maxResults = maxResults
        self.text = text
    }
}

struct PlaceGeometry: Equatable, Decodable {
    /// A single point geometry specifies a location for a Place using [WGS 84](https://gisgeography.com/wgs84-world-geodetic-system/) coordinates:
    ///
    /// * x — Specifies the x coordinate or longitude.
    ///
    /// * y — Specifies the y coordinate or latitude.
    var point: [Swift.Double]?

    init(
        point: [Swift.Double]? = nil
    )
    {
        self.point = point
    }
}

struct TimeZone: Equatable, Decodable {
    /// The name of the time zone, following the [ IANA time zone standard](https://www.iana.org/time-zones). For example, America/Los_Angeles.
    /// This member is required.
    var name: Swift.String?
    /// The time zone's offset, in seconds, from UTC.
    var offset: Swift.Int?

    init(
        name: Swift.String? = nil,
        offset: Swift.Int? = nil
    )
    {
        self.name = name
        self.offset = offset
    }
}

struct Place: Equatable, Decodable {
    /// The numerical portion of an address, such as a building number.
    var addressNumber: Swift.String?
    /// The Amazon Location categories that describe this Place. For more information about using categories, including a list of Amazon Location categories, see [Categories and filtering](https://docs.aws.amazon.com/location/latest/developerguide/category-filtering.html), in the Amazon Location Service Developer Guide.
    var categories: [Swift.String]?
    /// A country/region specified using [ISO 3166](https://www.iso.org/iso-3166-country-codes.html) 3-digit country/region code. For example, CAN.
    var country: Swift.String?
    /// Places uses a point geometry to specify a location or a Place.
    /// This member is required.
    var geometry: PlaceGeometry?
    /// True if the result is interpolated from other known places. False if the Place is a known place. Not returned when the partner does not provide the information. For example, returns False for an address location that is found in the partner data, but returns True if an address does not exist in the partner data and its location is calculated by interpolating between other known addresses.
    var interpolated: Swift.Bool?
    /// The full name and address of the point of interest such as a city, region, or country. For example, 123 Any Street, Any Town, USA.
    var label: Swift.String?
    /// A name for a local area, such as a city or town name. For example, Toronto.
    var municipality: Swift.String?
    /// The name of a community district. For example, Downtown.
    var neighborhood: Swift.String?
    /// A group of numbers and letters in a country-specific format, which accompanies the address for the purpose of identifying a location.
    var postalCode: Swift.String?
    /// A name for an area or geographical division, such as a province or state name. For example, British Columbia.
    var region: Swift.String?
    /// The name for a street or a road to identify a location. For example, Main Street.
    var street: Swift.String?
    /// A county, or an area that's part of a larger region. For example, Metro Vancouver.
    var subRegion: Swift.String?
    /// Categories from the data provider that describe the Place that are not mapped to any Amazon Location categories.
    var supplementalCategories: [Swift.String]?
    /// The time zone in which the Place is located. Returned only when using HERE or Grab as the selected partner.
    var timeZone: TimeZone?
    /// For addresses with multiple units, the unit identifier. Can include numbers and letters, for example 3B or Unit 123. Returned only for a place index that uses Esri or Grab as a data provider. Is not returned for SearchPlaceIndexForPosition.
    var unitNumber: Swift.String?
    /// For addresses with a UnitNumber, the type of unit. For example, Apartment. Returned only for a place index that uses Esri as a data provider.
    var unitType: Swift.String?

    init(
        addressNumber: Swift.String? = nil,
        categories: [Swift.String]? = nil,
        country: Swift.String? = nil,
        geometry: PlaceGeometry? = nil,
        interpolated: Swift.Bool? = nil,
        label: Swift.String? = nil,
        municipality: Swift.String? = nil,
        neighborhood: Swift.String? = nil,
        postalCode: Swift.String? = nil,
        region: Swift.String? = nil,
        street: Swift.String? = nil,
        subRegion: Swift.String? = nil,
        supplementalCategories: [Swift.String]? = nil,
        timeZone: TimeZone? = nil,
        unitNumber: Swift.String? = nil,
        unitType: Swift.String? = nil
    )
    {
        self.addressNumber = addressNumber
        self.categories = categories
        self.country = country
        self.geometry = geometry
        self.interpolated = interpolated
        self.label = label
        self.municipality = municipality
        self.neighborhood = neighborhood
        self.postalCode = postalCode
        self.region = region
        self.street = street
        self.subRegion = subRegion
        self.supplementalCategories = supplementalCategories
        self.timeZone = timeZone
        self.unitNumber = unitNumber
        self.unitType = unitType
    }
}

struct SearchForTextResult: Equatable, Decodable {
    /// The distance in meters of a great-circle arc between the bias position specified and the result. Distance will be returned only if a bias position was specified in the query. A great-circle arc is the shortest path on a sphere, in this case the Earth. This returns the shortest distance between two locations.
    var distance: Swift.Double?
    /// Details about the search result, such as its address and position.
    /// This member is required.
    var place: Place?
    /// The unique identifier of the place. You can use this with the GetPlace operation to find the place again later. For SearchPlaceIndexForText operations, the PlaceId is returned only by place indexes that use HERE or Grab as a data provider.
    var placeId: Swift.String?
    /// The relative confidence in the match for a result among the results returned. For example, if more fields for an address match (including house number, street, city, country/region, and postal code), the relevance score is closer to 1. Returned only when the partner selected is Esri or Grab.
    var relevance: Swift.Double?

    init(
        distance: Swift.Double? = nil,
        place: Place? = nil,
        placeId: Swift.String? = nil,
        relevance: Swift.Double? = nil
    )
    {
        self.distance = distance
        self.place = place
        self.placeId = placeId
        self.relevance = relevance
    }
}

struct SearchPlaceIndexForTextSummary: Swift.Equatable {
    /// Contains the coordinates for the optional bias position specified in the request. This parameter contains a pair of numbers. The first number represents the X coordinate, or longitude; the second number represents the Y coordinate, or latitude. For example, [-123.1174, 49.2847] represents the position with longitude -123.1174 and latitude 49.2847.
    var biasPosition: [Swift.Double]?
    /// The geospatial data provider attached to the place index resource specified in the request. Values can be one of the following:
    ///
    /// * Esri
    ///
    /// * Grab
    ///
    /// * Here
    ///
    ///
    /// For more information about data providers, see [Amazon Location Service data providers](https://docs.aws.amazon.com/location/latest/developerguide/what-is-data-provider.html).
    /// This member is required.
    var dataSource: Swift.String?
    /// Contains the coordinates for the optional bounding box specified in the request.
    var filterBBox: [Swift.Double]?
    /// The optional category filter specified in the request.
    var filterCategories: [Swift.String]?
    /// Contains the optional country filter specified in the request.
    var filterCountries: [Swift.String]?
    /// The preferred language used to return results. Matches the language in the request. The value is a valid [BCP 47](https://tools.ietf.org/search/bcp47) language tag, for example, en for English.
    var language: Swift.String?
    /// Contains the optional result count limit specified in the request.
    var maxResults: Swift.Int
    /// The bounding box that fully contains all search results. If you specified the optional FilterBBox parameter in the request, ResultBBox is contained within FilterBBox.
    var resultBBox: [Swift.Double]?
    /// The search text specified in the request.
    /// This member is required.
    var text: Swift.String?

    init(
        biasPosition: [Swift.Double]? = nil,
        dataSource: Swift.String? = nil,
        filterBBox: [Swift.Double]? = nil,
        filterCategories: [Swift.String]? = nil,
        filterCountries: [Swift.String]? = nil,
        language: Swift.String? = nil,
        maxResults: Swift.Int = 0,
        resultBBox: [Swift.Double]? = nil,
        text: Swift.String? = nil
    )
    {
        self.biasPosition = biasPosition
        self.dataSource = dataSource
        self.filterBBox = filterBBox
        self.filterCategories = filterCategories
        self.filterCountries = filterCountries
        self.language = language
        self.maxResults = maxResults
        self.resultBBox = resultBBox
        self.text = text
    }
}

struct SearchPlaceIndexForTextOutputResponse: Equatable, Decodable {
    /// A list of Places matching the input text. Each result contains additional information about the specific point of interest. Not all response properties are included with all responses. Some properties may only be returned by specific data partners.
    /// This member is required.
    var results: [SearchForTextResult]?
    /// Contains a summary of the request. Echoes the input values for BiasPosition, FilterBBox, FilterCountries, Language, MaxResults, and Text. Also includes the DataSource of the place index and the bounding box, ResultBBox, which surrounds the search results.
    /// This member is required.
    var summary: SearchPlaceIndexForTextSummary?

    init(
        results: [SearchForTextResult]? = nil,
        summary: SearchPlaceIndexForTextSummary? = nil
    )
    {
        self.results = results
        self.summary = summary
    }
}

struct SearchPlaceIndexForPositionInput: Swift.Equatable {
    /// The name of the place index resource you want to use for the search.
    /// This member is required.
    var indexName: Swift.String?
    /// The optional [API key](https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html) to authorize the request.
    var key: Swift.String?
    /// The preferred language used to return results. The value must be a valid [BCP 47](https://tools.ietf.org/search/bcp47) language tag, for example, en for English. This setting affects the languages used in the results, but not the results themselves. If no language is specified, or not supported for a particular result, the partner automatically chooses a language for the result. For an example, we'll use the Greek language. You search for a location around Athens, Greece, with the language parameter set to en. The city in the results will most likely be returned as Athens. If you set the language parameter to el, for Greek, then the city in the results will more likely be returned as Αθήνα. If the data provider does not have a value for Greek, the result will be in a language that the provider does support.
    var language: Swift.String?
    /// An optional parameter. The maximum number of results returned per request. Default value: 50
    var maxResults: Swift.Int
    /// Specifies the longitude and latitude of the position to query. This parameter must contain a pair of numbers. The first number represents the X coordinate, or longitude; the second number represents the Y coordinate, or latitude. For example, [-123.1174, 49.2847] represents a position with longitude -123.1174 and latitude 49.2847.
    /// This member is required.
    var position: [Swift.Double]?

    init(
        indexName: Swift.String? = nil,
        key: Swift.String? = nil,
        language: Swift.String? = nil,
        maxResults: Swift.Int = 0,
        position: [Swift.Double]? = nil
    )
    {
        self.indexName = indexName
        self.key = key
        self.language = language
        self.maxResults = maxResults
        self.position = position
    }
}

struct SearchForPositionResult: Swift.Equatable {
    /// The distance in meters of a great-circle arc between the query position and the result. A great-circle arc is the shortest path on a sphere, in this case the Earth. This returns the shortest distance between two locations.
    /// This member is required.
    var distance: Swift.Double?
    /// Details about the search result, such as its address and position.
    /// This member is required.
    var place: Place?
    /// The unique identifier of the place. You can use this with the GetPlace operation to find the place again later. For SearchPlaceIndexForPosition operations, the PlaceId is returned only by place indexes that use HERE or Grab as a data provider.
    var placeId: Swift.String?

    init(
        distance: Swift.Double? = nil,
        place: Place? = nil,
        placeId: Swift.String? = nil
    )
    {
        self.distance = distance
        self.place = place
        self.placeId = placeId
    }
}

struct SearchPlaceIndexForPositionSummary: Swift.Equatable {
    /// The geospatial data provider attached to the place index resource specified in the request. Values can be one of the following:
    ///
    /// * Esri
    ///
    /// * Grab
    ///
    /// * Here
    ///
    ///
    /// For more information about data providers, see [Amazon Location Service data providers](https://docs.aws.amazon.com/location/latest/developerguide/what-is-data-provider.html).
    /// This member is required.
    var dataSource: Swift.String?
    /// The preferred language used to return results. Matches the language in the request. The value is a valid [BCP 47](https://tools.ietf.org/search/bcp47) language tag, for example, en for English.
    var language: Swift.String?
    /// Contains the optional result count limit that is specified in the request. Default value: 50
    var maxResults: Swift.Int
    /// The position specified in the request.
    /// This member is required.
    var position: [Swift.Double]?

    init(
        dataSource: Swift.String? = nil,
        language: Swift.String? = nil,
        maxResults: Swift.Int = 0,
        position: [Swift.Double]? = nil
    )
    {
        self.dataSource = dataSource
        self.language = language
        self.maxResults = maxResults
        self.position = position
    }
}

struct SearchPlaceIndexForPositionOutputResponse: Swift.Equatable {
    /// Returns a list of Places closest to the specified position. Each result contains additional information about the Places returned.
    /// This member is required.
    var results: [SearchForPositionResult]?
    /// Contains a summary of the request. Echoes the input values for Position, Language, MaxResults, and the DataSource of the place index.
    /// This member is required.
    var summary: SearchPlaceIndexForPositionSummary?

    init(
        results: [SearchForPositionResult]? = nil,
        summary: SearchPlaceIndexForPositionSummary? = nil
    )
    {
        self.results = results
        self.summary = summary
    }
}

