//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import AmplifyTestCommon

class TestUser5: NSCopying {
    var model: FlutterSerializedModel
    
    init(id: String, username: String) throws {
        self.model = FlutterSerializedModel(id: id, map: try FlutterDataStoreRequestUtils.getJSONValue(["username": username]))
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

    func username() -> JSONValue? {
        return self.model.values["username"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TestUser5(model: model)
        return copy
    }
}

