//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import AmplifyTestCommon

class TestPost: NSCopying {
    var model: FlutterSerializedModel
    
    init(id: String = UUID().uuidString, title: String, content: String, createdAt: String) throws {
        let map: [String: Any] = [
            "title": title,
            "content": content,
            "createdAt": createdAt
        ]
        self.model = FlutterSerializedModel(id: id, map: try FlutterDataStoreRequestUtils.getJSONValue(map))
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
    
    func content() -> JSONValue? {
        return self.model.values["content"]
    }
    
    func createdAt() -> JSONValue? {
        return self.model.values["createdAt"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TestPost(model: model)
        return copy
    }
}


