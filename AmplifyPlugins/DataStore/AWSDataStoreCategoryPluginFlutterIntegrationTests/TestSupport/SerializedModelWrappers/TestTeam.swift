//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import AmplifyTestCommon

class TestTeam: NSCopying {
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
        let copy = TestTeam(model: model)
        return copy
    }
}

