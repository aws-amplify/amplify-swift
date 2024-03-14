//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyUnifiedConfiguration) import Amplify
import Foundation
import AWSLocation

public struct AWSLocationGeoPluginConfiguration {
    private static func urlString(regionName: String, mapName: String) -> String {
        "https://maps.geo.\(regionName).amazonaws.com/maps/v0/maps/\(mapName)/style-descriptor"
    }

    let defaultMap: String?
    let maps: [String: Geo.MapStyle]
    let defaultSearchIndex: String?
    let searchIndices: [String]

    public let regionName: String

    init(config: JSONValue) throws {
        let configObject = try AWSLocationGeoPluginConfiguration.getConfigObject(section: .plugin,
                                                                                 configJSON: config)
        let regionName = try AWSLocationGeoPluginConfiguration.getRegion(configObject)

        var maps = [String: Geo.MapStyle]()
        var defaultMap: String?
        if let mapsConfigJSON = configObject[Section.maps.key] {
            let mapsConfigObject = try AWSLocationGeoPluginConfiguration.getConfigObject(section: .maps,
                                                                                      configJSON: mapsConfigJSON)
            maps = try AWSLocationGeoPluginConfiguration.getMaps(mapConfig: mapsConfigObject, regionName: regionName)
            defaultMap = try AWSLocationGeoPluginConfiguration.getDefault(section: .maps,
                                                                       configObject: mapsConfigObject)
            guard let map = defaultMap, maps[map] != nil else {
                throw GeoPluginConfigError.mapDefaultNotFound(mapName: defaultMap)
            }
        }

        var searchIndices = [String]()
        var defaultSearchIndex: String?
        if let searchConfigJSON = configObject[Section.searchIndices.key] {
            let searchConfigObject = try AWSLocationGeoPluginConfiguration.getConfigObject(section: .searchIndices,
                                                                                        configJSON: searchConfigJSON)
            searchIndices = try AWSLocationGeoPluginConfiguration.getItemsStrings(section: .searchIndices,
                                                                                  configObject: searchConfigObject)
            defaultSearchIndex = try AWSLocationGeoPluginConfiguration.getDefault(section: .searchIndices,
                                                                               configObject: searchConfigObject)

            guard let index = defaultSearchIndex, searchIndices.contains(index) else {
                throw GeoPluginConfigError.searchDefaultNotFound(indexName: defaultSearchIndex)
            }
        }

        self.init(regionName: regionName,
                  defaultMap: defaultMap,
                  maps: maps,
                  defaultSearchIndex: defaultSearchIndex,
                  searchIndices: searchIndices)
    }
    
    init(config: AmplifyConfigurationV2) throws {
        guard let geo = config.geo else {
            throw GeoPluginConfigError.configurationInvalid(section: .plugin)
        }

        let maps = try AWSLocationGeoPluginConfiguration.getMaps(
            mapConfig: geo.maps,
            regionName: geo.awsRegion)

        self.init(regionName: geo.awsRegion,
                  defaultMap: geo.maps.default,
                  maps: maps,
                  defaultSearchIndex: geo.searchIndices.default,
                  searchIndices: geo.searchIndices.items)
    }

    init(regionName: String,
         defaultMap: String?,
         maps: [String: Geo.MapStyle],
         defaultSearchIndex: String?,
         searchIndices: [String]) {
        self.regionName = regionName
        self.defaultMap = defaultMap
        self.maps = maps
        self.defaultSearchIndex = defaultSearchIndex
        self.searchIndices = searchIndices
    }

    // MARK: - Private helper methods

    private static func getRegion(_ configObject: [String: JSONValue]) throws -> String {
        guard let regionJSON = configObject[Node.region.key] else {
            throw GeoPluginConfigError.regionMissing
        }

        guard case let .string(region) = regionJSON else {
            throw GeoPluginConfigError.regionInvalid
        }

        if region.isEmpty {
            throw GeoPluginConfigError.regionEmpty
        }

        guard region != "Unknown" else {
            throw GeoPluginConfigError.regionMissing
        }

        return region
    }

    private static func getDefault(section: Section, configObject: [String: JSONValue]) throws -> String {
        guard let defaultJSON = configObject[Node.default.key] else {
            throw GeoPluginConfigError.defaultMissing(section: section)
        }

        guard case let .string(defaultItem) = defaultJSON else {
            throw GeoPluginConfigError.defaultNotString(section: section)
        }

        if defaultItem.isEmpty {
            throw GeoPluginConfigError.defaultIsEmpty(section: section)
        }

        return defaultItem
    }

    private static func getConfigObject(section: Section, configJSON: JSONValue) throws -> [String: JSONValue] {
        guard case let .object(configObject) = configJSON else {
            throw GeoPluginConfigError.configurationInvalid(section: section)
        }
        return configObject
    }

    private static func getItemsJSON(section: Section, configObject: [String: JSONValue]) throws -> JSONValue {
        guard let itemsJSON = configObject[Node.items.key] else {
            throw GeoPluginConfigError.itemsMissing(section: section)
        }
        return itemsJSON
    }

    private static func getItemsObject(section: Section,
                                       configObject: [String: JSONValue]) throws -> [String: JSONValue] {
        let itemsJSON = try getItemsJSON(section: section, configObject: configObject)
        let itemsObject = try getConfigObject(section: section, configJSON: itemsJSON)
        return itemsObject
    }

    private static func getItemsStrings(section: Section, configObject: [String: JSONValue]) throws -> [String] {
        let itemsJSON = try getItemsJSON(section: section, configObject: configObject)
        guard case let .array(itemsArray) = itemsJSON else {
            throw GeoPluginConfigError.itemsInvalid(section: section)
        }
        let itemStrings: [String] = try itemsArray.map { item in
            guard case let .string(itemString) = item else {
                throw GeoPluginConfigError.itemsIsNotStringArray(section: section)
            }
            return itemString
        }
        return itemStrings
    }

    // MARK: - Maps
    private static func getMaps(mapConfig: [String: JSONValue], regionName: String) throws -> [String: Geo.MapStyle] {
        let mapItemsObject = try getItemsObject(section: .maps, configObject: mapConfig)

        let mapTuples: [(String, Geo.MapStyle)] = try mapItemsObject.map { mapName, itemJSON in
            guard case let .object(itemObject) = itemJSON else {
                throw GeoPluginConfigError.mapInvalid(mapName: mapName)
            }

            guard let styleJSON = itemObject[Node.style.key] else {
                throw GeoPluginConfigError.mapStyleMissing(mapName: mapName)
            }

            guard case let .string(style) = styleJSON else {
                throw GeoPluginConfigError.mapStyleIsNotString(mapName: mapName)
            }

            let url = URL(string: AWSLocationGeoPluginConfiguration.urlString(regionName: regionName,
                                                                              mapName: mapName))
            guard let styleURL = url else {
                throw GeoPluginConfigError.mapStyleURLInvalid(mapName: mapName)
            }

            let mapStyle = Geo.MapStyle.init(mapName: mapName, style: style, styleURL: styleURL)

            return (mapName, mapStyle)
        }
        let mapStyles = Dictionary(uniqueKeysWithValues: mapTuples)

        return mapStyles
    }

    private static func getMaps(mapConfig: AmplifyConfigurationV2.Geo.Maps,
                                regionName: String) throws -> [String: Geo.MapStyle] {
        let mapTuples: [(String, Geo.MapStyle)] = try mapConfig.items.map { map in
            let url = URL(string: AWSLocationGeoPluginConfiguration.urlString(regionName: regionName,
                                                                              mapName: map.name))
            guard let styleURL = url else {
                throw GeoPluginConfigError.mapStyleURLInvalid(mapName: map.name)
            }
            let mapStyle = Geo.MapStyle.init(mapName: map.name, style: map.style, styleURL: styleURL)
            return (map.name, mapStyle)
        }

        return Dictionary(uniqueKeysWithValues: mapTuples)
    }
}
