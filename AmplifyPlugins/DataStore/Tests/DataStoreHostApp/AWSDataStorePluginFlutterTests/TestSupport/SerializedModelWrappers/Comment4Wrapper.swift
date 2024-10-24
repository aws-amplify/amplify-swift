//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyTestCommon
import Foundation

/**
 Creates a convenience wrapper for non-model type instantiations so that tests do not need to directly access json.

 Wraps: Comment4
 */
class Comment4Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(id: String = UUID().uuidString, content: String, post: FlutterSerializedModel) throws {
        self.model = try FlutterSerializedModel(id: UUID().uuidString, map: FlutterDataStoreRequestUtils.getJSONValue(["content": content, "post": post.toMap(modelSchema: Post4.schema)]))
    }

    init(model: FlutterSerializedModel) {
        self.model = model
    }

    init(json: String) throws {
        let data = Data(json.utf8)
        let map = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        self.model = try FlutterSerializedModel(id: map!["id"] as! String, map: FlutterDataStoreRequestUtils.getJSONValue(map!))
    }

    func setPost(post: FlutterSerializedModel) throws {
        model = try FlutterSerializedModel(id: model.id, map: FlutterDataStoreRequestUtils.getJSONValue(["content": "content", "post": post.toMap(modelSchema: Post4.schema)]))
    }

    func idString() -> String {
        return model.id
    }

    func id() -> JSONValue? {
        return model.values["id"]
    }

    func post() -> JSONValue? {
        return model.values["post"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Comment4Wrapper(model: model)
        return copy
    }
}
