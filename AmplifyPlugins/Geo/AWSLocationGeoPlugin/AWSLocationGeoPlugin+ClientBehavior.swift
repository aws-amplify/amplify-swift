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

extension AWSLocationGeoPlugin {

    // MARK: - Search

    /// Search for places or points of interest.
    /// - Parameters:
    ///   - text: The place name or address to be used in the search. (case insensitive)
    ///   - area: The area (.near or .boundingBox) for the search. (optional)
    ///   - countries: Limits the search to the given a list of countries/regions. (optional)
    ///   - maxResults: The maximum number of results returned per request. (optional)
    ///   - placeIndexName: The name of the Place Index to query. (optional)
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    public func search(for text: String,
                       area: Geo.SearchArea? = nil,
                       countries: [Geo.Country]? = nil,
                       maxResults: Int? = nil,
                       placeIndexName: String? = nil,
                       completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>) {

        assert(pluginConfig.defaultSearchIndex != nil, GeoPluginConfigError.searchConfigMissing)

        let request = AWSLocationSearchPlaceIndexForTextRequest()!
        request.indexName = placeIndexName ?? pluginConfig.defaultSearchIndex
        request.text = text

        if let area = area {
            switch area {
            case .near(let coordinates):
                request.biasPosition = [coordinates.longitude as NSNumber,
                                        coordinates.latitude as NSNumber]
            case .within(let bbox):
                request.filterBBox = [bbox.southwest.longitude as NSNumber,
                                      bbox.southwest.latitude as NSNumber,
                                      bbox.northeast.longitude as NSNumber,
                                      bbox.northeast.latitude as NSNumber]
            }
        }

        if let countries = countries {
            request.filterCountries = countries.map { country in
                String(describing: country)
            }
        }

        if let maxResults = maxResults {
            request.maxResults = maxResults as NSNumber
        }

        locationService.searchPlaceIndex(forText: request) { response, error in
            completionHandler(AWSLocationGeoPlugin.parsePlaceResponse(response: response, error: error))
        }
    }

    /// Reverse geocodes a given pair of coordinates and returns a list of Places
    /// closest to the specified position.
    /// - Parameters:
    ///   - coordinates: Specifies a coordinate for the query.
    ///   - maxResults: The maximum number of results returned per request. (optional)
    ///   - placeIndexName: The name of the Place Index to query. (optional)
    ///   - completionHandler: The completion handler receives a Response object.  The
    ///   success case provides a Place array.
    public func search(for coordinates: Geo.Coordinates,
                       maxResults: Int? = nil,
                       placeIndexName: String? = nil,
                       completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>) {

        assert(pluginConfig.defaultSearchIndex != nil, GeoPluginConfigError.searchConfigMissing)

        let request = AWSLocationSearchPlaceIndexForPositionRequest()!
        request.indexName = placeIndexName ?? pluginConfig.defaultSearchIndex
        request.position = [coordinates.longitude as NSNumber,
                            coordinates.latitude as NSNumber]

        if let maxResults = maxResults {
            request.maxResults = maxResults as NSNumber
        }

        locationService.searchPlaceIndex(forPosition: request) { response, error in
            completionHandler(AWSLocationGeoPlugin.parsePlaceResponse(response: response, error: error))
        }
    }

    static private func parsePlaceResponse(response: AWSModel?, error: Error?) -> Result<[Geo.Place], Error> {
        if let error = error {
            return .failure(error)
        }

        var results = [AWSLocationPlace]()

        if let responseResults = (response as? AWSLocationSearchPlaceIndexForTextResponse)?.results {
            results = responseResults.compactMap {
                $0.place
            }
        }

        if let responseResults = (response as? AWSLocationSearchPlaceIndexForPositionResponse)?.results {
            results = responseResults.compactMap {
                $0.place
            }
        }

        let places: [Geo.Place] = results.compactMap {
            guard let long = $0.geometry?.point?.first as? Double,
                  let lat = $0.geometry?.point?.last as? Double
            else {
                return nil
            }

            return Geo.Place(coordinates: Geo.Coordinates(latitude: lat, longitude: long),
                             label: $0.label,
                             addressNumber: $0.addressNumber,
                             street: $0.street,
                             municipality: $0.municipality,
                             region: $0.region,
                             subRegion: $0.subRegion,
                             postalCode: $0.postalCode,
                             country: $0.country)
        }

        return .success(places)
    }

    // MARK: - Maps

    /// Retrieves metadata for available map resources.
    /// - Returns: Metadata for all available map resources.
    public func getAvailableMaps()  -> [Geo.MapStyle] {
        let mapStyles = Array(pluginConfig.maps.values)
        assert(!mapStyles.isEmpty, GeoPluginConfigError.mapConfigMissing)

        return mapStyles
    }

    /// Retrieves the default map resource.
    /// - Returns: Metadata for the default map resource.
    public func getDefaultMap() -> Geo.MapStyle? {
        guard let mapName = pluginConfig.defaultMap, let mapStyle = pluginConfig.maps[mapName] else {
            assertionFailure(GeoPluginConfigError.mapConfigMissing)
            return nil
        }

        return mapStyle
    }
}
