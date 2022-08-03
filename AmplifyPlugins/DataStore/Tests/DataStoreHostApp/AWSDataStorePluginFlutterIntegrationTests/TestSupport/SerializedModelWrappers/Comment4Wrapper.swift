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
 
 Wraps: Comment4
 */
class Comment4Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(id: String = UUID().uuidString, content: String, post: FlutterSerializedModel) throws {
        self.model = FlutterSerializedModel(id: UUID().uuidString, map: try FlutterDataStoreRequestUtils.getJSONValue(["content": content, "post": post.toMap(modelSchema: Post4.schema)]))
    }

    init(model: FlutterSerializedModel) {
        self.model = model
    }

    init(json: String) throws {
        let data = json.data(using: .utf8)!
        let map = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        self.model = FlutterSerializedModel(id: map!["id"] as! String, map: try FlutterDataStoreRequestUtils.getJSONValue(map!))
    }

    func setPost(post: FlutterSerializedModel) throws {
        self.model = FlutterSerializedModel(id: self.model.id, map: try FlutterDataStoreRequestUtils.getJSONValue(["content": "content", "post": post.toMap(modelSchema: Post4.schema)]))
    }

    func idString() -> String {
        return self.model.id
    }

    func id() -> JSONValue? {
        return self.model.values["id"]
    }

    func post() -> JSONValue? {
        return self.model.values["post"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Comment4Wrapper(model: model)
        return copy
    }
}
