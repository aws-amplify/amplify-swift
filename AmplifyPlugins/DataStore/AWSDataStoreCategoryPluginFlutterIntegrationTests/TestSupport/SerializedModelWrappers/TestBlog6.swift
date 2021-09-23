//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import AmplifyTestCommon

class TestBlog6: NSCopying {
    var model: FlutterSerializedModel
    
    init(name: String) throws {
        let map: [String: Any] = [
            "name": name
        ]
        self.model = FlutterSerializedModel(id: UUID().uuidString, map: try FlutterDataStoreRequestUtils.getJSONValue(map))
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

    func name() -> JSONValue? {
        return self.model.values["name"]
    }
    
    func posts() -> JSONValue? {
        return self.model.values["posts"]
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TestBlog6(model: model)
        return copy
    }
}


