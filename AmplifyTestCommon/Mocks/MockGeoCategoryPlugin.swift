//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// `@unchecked Sendable` because the category plugin protocols now require `Sendable` (see
// `Plugin`), and a `Sendable` class may not inherit from a non-`NSObject` superclass. These are
// test doubles driven from a single test at a time.
class MockGeoCategoryPlugin: MessageReporter, GeoCategoryPlugin, @unchecked Sendable {
    var key: String {
        return "MockGeoCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset() {
        notify("reset")
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
        Geo.MapStyle(
            mapName: "MapName",
            style: "MapStyle",
            styleURL: URL(string: "http://MapStyleURL")!
        )
    }

    private func createPlace() -> Geo.Place {
        Geo.Place(
            coordinates: Geo.Coordinates(latitude: 0, longitude: 0),
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

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double.

class MockSecondGeoCategoryPlugin: MockGeoCategoryPlugin, @unchecked Sendable {
    override var key: String {
        return "MockSecondGeoCategoryPlugin"
    }
}
