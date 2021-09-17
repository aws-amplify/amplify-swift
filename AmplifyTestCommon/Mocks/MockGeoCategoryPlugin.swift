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
                area: Geo.SearchArea? = nil,
                countries: [Geo.Country]? = nil,
                maxResults: Int? = nil,
                placeIndexName: String? = nil,
                completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>) {

        notify("search(for text:\(text))")
        completionHandler(.success([createPlace()]))
    }

    func search(for coordinates: Geo.Coordinates,
                maxResults: Int?,
                placeIndexName: String?,
                completionHandler: @escaping Geo.ResultsHandler<[Geo.Place]>) {

        notify("search(for coordinates:\(coordinates))")
        completionHandler(.success([createPlace()]))
    }

    func getAvailableMaps() -> [Geo.MapStyle] {
        notify()

        return [createMapStyle()]
    }

    func getDefaultMap() -> Geo.MapStyle {
        notify()

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
