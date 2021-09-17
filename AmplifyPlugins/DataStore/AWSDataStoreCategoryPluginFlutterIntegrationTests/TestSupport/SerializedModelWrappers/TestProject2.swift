//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import AmplifyTestCommon

class TestProject2: NSCopying {
    var model: FlutterSerializedModel
        
    init(name: String, team: FlutterSerializedModel, teamID: String) throws {
        self.model = FlutterSerializedModel(id: UUID().uuidString, map: try FlutterDataStoreRequestUtils.getJSONValue(["name": name, "team": team.toMap(modelSchema: Team1.schema), "teamID": teamID]))
    }
    
    init(model: FlutterSerializedModel) {
        self.model = model;
    }
    
    func setTeam(name: String, team: FlutterSerializedModel, teamID: String) throws {
        self.model = FlutterSerializedModel(id: self.model.id, map: try FlutterDataStoreRequestUtils.getJSONValue(["name": name, "team": team.toMap(modelSchema: Team1.schema), "teamID": teamID]))
    }
    
    func idString() -> String {
        return self.model.id
    }
    
    func id() -> JSONValue? {
        return self.model.values["id"]
    }

    func teamID() -> JSONValue? {
        return self.model.values["team"]!["id"]
    }
    
    func teamName() -> JSONValue? {
        return self.model.values["team"]!["name"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TestProject(model: model)
        return copy
    }
}
