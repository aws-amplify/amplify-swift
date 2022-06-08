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
 
 Wraps: Project1
 */
class Project1Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(team: FlutterSerializedModel) throws {
        self.model = FlutterSerializedModel(id: UUID().uuidString, map: try FlutterDataStoreRequestUtils.getJSONValue(["team": team.toMap(modelSchema: Team1.schema)]))
    }

    init(name: String, team: FlutterSerializedModel) throws {
        self.model = FlutterSerializedModel(id: UUID().uuidString, map: try FlutterDataStoreRequestUtils.getJSONValue(["name": name, "team": team.toMap(modelSchema: Team1.schema)]))
    }

    init(model: FlutterSerializedModel) {
        self.model = model
    }

    func setTeam(team: FlutterSerializedModel) throws {
        self.model = FlutterSerializedModel(id: self.model.id, map: try FlutterDataStoreRequestUtils.getJSONValue(["team": team.toMap(modelSchema: Team1.schema)]))
    }

    func idString() -> String {
        return self.model.id
    }

    func id() -> JSONValue? {
        return self.model.values["id"]
    }

    func teamId() -> JSONValue? {
        return self.model.values["team"]!["id"]
    }

    func teamName() -> JSONValue? {
        return self.model.values["team"]!["name"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Project1Wrapper(model: model)
        return copy
    }
}
