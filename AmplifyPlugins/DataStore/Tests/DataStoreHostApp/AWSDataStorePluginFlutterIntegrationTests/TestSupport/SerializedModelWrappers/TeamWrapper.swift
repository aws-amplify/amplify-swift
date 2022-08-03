//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AmplifyTestCommon

/**
 Creates a convenience wrapper for non-model type instantiations so that tests do not need to directly access json.
 
 Wraps: Team1 and Team 2
 */
class TeamWrapper: NSCopying {
    var model: FlutterSerializedModel

    init(name: String) throws {
        self.model = FlutterSerializedModel(id: UUID().uuidString, map: try FlutterDataStoreRequestUtils.getJSONValue(["name": name]))
    }

    init(model: FlutterSerializedModel) {
        self.model = model
    }

    func idString() -> String {
        return self.model.id
    }

    func id() -> JSONValue? {
        return self.model.values["id"]
    }

    func teamName() -> JSONValue? {
        return self.model.values["name"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TeamWrapper(model: model)
        return copy
    }
}
