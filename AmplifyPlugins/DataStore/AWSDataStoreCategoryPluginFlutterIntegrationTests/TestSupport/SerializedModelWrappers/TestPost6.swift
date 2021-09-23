//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import AmplifyTestCommon

class TestPost6: NSCopying {
    var model: FlutterSerializedModel
    
    init(title: String, blog: FlutterSerializedModel) throws {
        let map: [String: Any] = [
            "title": title,
            "blog": blog.toMap(modelSchema: Blog6.schema)
        ]
        self.model = FlutterSerializedModel(id: UUID().uuidString, map: try FlutterDataStoreRequestUtils.getJSONValue(map))
    }
    
    init(model: FlutterSerializedModel) {
        self.model = model
    }
    
    init(json: String) throws {
        let data = json.data(using: .utf8)!
        let map = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]
        self.model = FlutterSerializedModel(id: map!["id"] as! String, map: try FlutterDataStoreRequestUtils.getJSONValue(map!))
    }

    
    func idString() -> String {
        return self.model.id
    }
    
    func id() -> JSONValue? {
        return self.model.values["id"]
    }

    func title() -> JSONValue? {
        return self.model.values["title"]
    }
    
    func blog() -> JSONValue? {
        return self.model.values["blog"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TestPost3(model: model)
        return copy
    }
}


