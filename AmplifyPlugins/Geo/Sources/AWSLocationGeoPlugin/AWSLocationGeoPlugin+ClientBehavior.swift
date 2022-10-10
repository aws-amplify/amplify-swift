//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

import AWSLocation

extension AWSLocationGeoPlugin {

    // MARK: - Search

    /// Search for places or points of interest.
    /// - Parameters:
    ///   - text: The place name or address to be used in the search. (case insensitive)
    ///   - area: The area (.near or .boundingBox) for the search. (optional)
    ///   - countries: Limits the search to the given a list of countries/regions. (optional)
    ///   - maxResults: The maximum number of results returned per request. (optional)
    ///   - placeIndexName: The name of the Place Index to query. (optional)
    /// - Returns :
    ///     It returns a Geo.Place array.
    /// - Throws:
    ///     `Geo.Error.accessDenied` if request authorization issue
    ///     `Geo.Error.serviceError` if service is down/resource not found/throttling/validation error
    ///     `Geo.Error.invalidConfiguration` if invalid configuration
    ///     `Geo.Error.networkError` if request failed or network unavailable
    ///     `Geo.Error.pluginError` if encapsulated error received by a dependent plugin
    ///     `Geo.Error.unknown` if error is unknown
    public func search(for text: String,
                       options: Geo.SearchForTextOptions? = nil) async throws -> [Geo.Place] {

        var request = SearchPlaceIndexForTextInput()

        request.indexName = (options?.pluginOptions as? AWSLocationGeoPluginSearchOptions)?
            .searchIndex ?? pluginConfig.defaultSearchIndex

        guard request.indexName != nil else {
            throw Geo.Error.invalidConfiguration(
                GeoPluginErrorConstants.missingDefaultSearchIndex.errorDescription,
                GeoPluginErrorConstants.missingDefaultSearchIndex.recoverySuggestion)
        }

        request.text = text

        if let area = options?.area {
            switch area {
            case .near(let coordinates):
                request.biasPosition = [coordinates.longitude,
                                        coordinates.latitude]
            case .within(let boundingBox):
                request.filterBBox = [boundingBox.southwest.longitude,
                                      boundingBox.southwest.latitude,
                                      boundingBox.northeast.longitude,
                                      boundingBox.northeast.latitude]
            }
        }

        if let countries = options?.countries {
            request.filterCountries = countries.map { country in
                country.code
            }
        }

        if let maxResults = options?.maxResults {
            request.maxResults = maxResults as Int
        }

        do {
            let response = try await locationService.searchPlaceIndex(forText: request)
            var results = [LocationClientTypes.Place]()
            if let responseResults = response.results {
                results = responseResults.compactMap {
                    $0.place
                }
            }

            let places: [Geo.Place] = results.compactMap {
                guard let long = $0.geometry?.point?.first,
                      let lat = $0.geometry?.point?.last
                else {
                    return nil
                }

                return Geo.Place(coordinates: Geo.Coordinates(latitude: lat, longitude: long),
                                 label: $0.label,
                                 addressNumber: $0.addressNumber,
                                 street: $0.street,
                                 municipality: $0.municipality,
                                 neighborhood: $0.neighborhood,
                                 region: $0.region,
                                 subRegion: $0.subRegion,
                                 postalCode: $0.postalCode,
                                 country: $0.country)
            }
            return places
        } catch {
            let geoError = GeoErrorHelper.mapAWSLocationError(error)
            throw geoError
        }
    }

    /// Reverse geocodes a given pair of coordinates and returns a list of Places
    /// closest to the specified position.
    /// - Parameters:
    ///   - coordinates: Specifies a coordinate for the query.
    ///   - maxResults: The maximum number of results returned per request. (optional)
    ///   - placeIndexName: The name of the Place Index to query. (optional)
    /// - Return value :
    ///     It returns a Geo.Place array.
    /// - Throws:
    ///     `Geo.Error.accessDenied` if request authorization issue
    ///     `Geo.Error.serviceError` if service is down/resource not found/throttling/validation error
    ///     `Geo.Error.invalidConfiguration` if invalid configuration
    ///     `Geo.Error.networkError` if request failed or network unavailable
    ///     `Geo.Error.pluginError` if encapsulated error received by a dependent plugin
    ///     `Geo.Error.unknown` if error is unknown
    public func search(for coordinates: Geo.Coordinates,
                       options: Geo.SearchForCoordinatesOptions? = nil) async throws -> [Geo.Place] {

        var request = SearchPlaceIndexForPositionInput()

        request.indexName = (options?.pluginOptions as? AWSLocationGeoPluginSearchOptions)?
            .searchIndex ?? pluginConfig.defaultSearchIndex

        guard request.indexName != nil else {
            throw Geo.Error.invalidConfiguration(
                GeoPluginErrorConstants.missingDefaultSearchIndex.errorDescription,
                GeoPluginErrorConstants.missingDefaultSearchIndex.recoverySuggestion)
        }

        request.position = [coordinates.longitude,
                            coordinates.latitude]

        if let maxResults = options?.maxResults {
            request.maxResults = maxResults as Int
        }

        do {
            let response = try await locationService.searchPlaceIndex(forPosition: request)
            var results = [LocationClientTypes.Place]()
            if let responseResults = response.results {
                results = responseResults.compactMap {
                    $0.place
                }
            }

            let places: [Geo.Place] = results.compactMap {
                guard let long = $0.geometry?.point?.first,
                      let lat = $0.geometry?.point?.last
                else {
                    return nil
                }

                return Geo.Place(coordinates: Geo.Coordinates(latitude: lat, longitude: long),
                                 label: $0.label,
                                 addressNumber: $0.addressNumber,
                                 street: $0.street,
                                 municipality: $0.municipality,
                                 neighborhood: $0.neighborhood,
                                 region: $0.region,
                                 subRegion: $0.subRegion,
                                 postalCode: $0.postalCode,
                                 country: $0.country)
            }
            return places
        } catch {
            let geoError = GeoErrorHelper.mapAWSLocationError(error)
            throw geoError
        }
    }

    // MARK: - Maps

    /// Retrieves metadata for available map resources.
    /// - Returns: Metadata for all available map resources.
    /// - Throws:
    ///     `Geo.Error.accessDenied` if request authorization issue
    ///     `Geo.Error.serviceError` if service is down/resource not found/throttling/validation error
    ///     `Geo.Error.invalidConfiguration` if invalid configuration
    ///     `Geo.Error.networkError` if request failed or network unavailable
    ///     `Geo.Error.pluginError` if encapsulated error received by a dependent plugin
    ///     `Geo.Error.unknown` if error is unknown
    public func availableMaps() async throws -> [Geo.MapStyle] {
        let mapStyles = Array(pluginConfig.maps.values)
        guard !mapStyles.isEmpty else {
            throw Geo.Error.invalidConfiguration(
                GeoPluginErrorConstants.missingMaps.errorDescription,
                GeoPluginErrorConstants.missingMaps.recoverySuggestion)
        }
        return mapStyles
    }

    /// Retrieves the default map resource.
    /// - Returns: Metadata for the default map resource.
    /// - Throws:
    ///     `Geo.Error.accessDenied` if request authorization issue
    ///     `Geo.Error.serviceError` if service is down/resource not found/throttling/validation error
    ///     `Geo.Error.invalidConfiguration` if invalid configuration
    ///     `Geo.Error.networkError` if request failed or network unavailable
    ///     `Geo.Error.pluginError` if encapsulated error received by a dependent plugin
    ///     `Geo.Error.unknown` if error is unknown
    public func defaultMap() async throws -> Geo.MapStyle {
        guard let mapName = pluginConfig.defaultMap, let mapStyle = pluginConfig.maps[mapName] else {
            throw Geo.Error.invalidConfiguration(
                GeoPluginErrorConstants.missingDefaultMap.errorDescription,
                GeoPluginErrorConstants.missingDefaultMap.recoverySuggestion)
        }
        return mapStyle
    }
}
