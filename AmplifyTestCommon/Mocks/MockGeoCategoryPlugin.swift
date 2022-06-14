//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class MockGeoCategoryPlugin: MessageReporter, GeoCategoryPlugin {
    var key: String {
        return "MockGeoCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset(onComplete: @escaping BasicClosure) {
        notify("reset")
        onComplete()
    }

    func search(for text: String, options: Geo.SearchForTextOptions?) async throws -> [Geo.Place] {
        notify("search(for text:\(text))")
        return [createPlace()]
    }

    func search(for coordinates: Geo.Coordinates, options: Geo.SearchForCoordinatesOptions?) async throws -> [Geo.Place] {
        notify("search(for coordinates:\(coordinates))")
        return [createPlace()]
    }

    func availableMaps() async throws -> [Geo.MapStyle] {
        notify("availableMaps")
        return [createMapStyle()]
    }

    func defaultMap() async throws -> Geo.MapStyle {
        notify("defaultMap")
        return createMapStyle()
    }

    private func createMapStyle() -> Geo.MapStyle {
        Geo.MapStyle(mapName: "MapName",
                 style: "MapStyle",
                 styleURL: URL(string: "http://MapStyleURL")!)
    }

    private func createPlace() -> Geo.Place {
        Geo.Place(coordinates: Geo.Coordinates(latitude: 0, longitude: 0),
                  label: "Place Label",
                  addressNumber: nil,
                  street: nil,
                  municipality: nil,
                  neighborhood: nil,
                  region: nil,
                  subRegion: nil,
                  postalCode: nil,
                  country: nil
        )
    }
}

class MockSecondGeoCategoryPlugin: MockGeoCategoryPlugin {
    override var key: String {
        return "MockSecondGeoCategoryPlugin"
    }
}
