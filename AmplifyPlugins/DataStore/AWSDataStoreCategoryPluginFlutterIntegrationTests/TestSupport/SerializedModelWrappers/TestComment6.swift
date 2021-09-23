//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import AmplifyTestCommon

class TestComment6: NSCopying {
    var model: FlutterSerializedModel

    init(content: String, post: FlutterSerializedModel) throws {
        let map: [String: Any] = [
            "content": content,
            "post": post.toMap(modelSchema: Post6.schema)
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

    func content() -> JSONValue? {
        return self.model.values["content"]
    }
    func post() -> JSONValue? {
        return self.model.values["post"]
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TestBlog6(model: model)
        return copy
    }
}

