//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

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

    func search(for text: String,
                area: SearchArea? = nil,
                countries: [String]? = nil,
                maxResults: Int? = nil,
                placeIndexName: String? = nil,
                completionHandler: @escaping GeoResultsHandler<[Place]>) {

        notify("search(for text:\(text))")
        completionHandler(.success([createPlace()]))
    }

    func search(for coordinates: Coordinates,
                maxResults: Int?,
                placeIndexName: String?,
                completionHandler: @escaping GeoResultsHandler<[Place]>) {

        notify("search(for coordinates:\(coordinates))")
        completionHandler(.success([createPlace()]))
    }

    func getAvailableMaps() -> [MapStyle] {
        notify()

        return [createMapStyle()]
    }

    func getDefaultMap() -> MapStyle {
        notify()

        return createMapStyle()
    }

    private func createMapStyle() -> MapStyle {
        MapStyle(mapName: "MapName",
                 style: "MapStyle",
                 styleURL: URL(string: "http://MapStyleURL")!)
    }

    private func createPlace() -> Place {
        Place(label: "Place Label",
              coordinates: Coordinates(latitude: 0, longitude: 0),
              addressNumber: nil,
              street: nil,
              municipality: nil,
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
