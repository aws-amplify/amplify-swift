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

 Wraps: Comment3
 */

class Comment3Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(id: String = UUID().uuidString, postID: String, content: String) throws {
        let map: [String: Any] = [
            "postID": postID,
            "content": content
        ]
        self.model = try FlutterSerializedModel(id: id, map: FlutterDataStoreRequestUtils.getJSONValue(map))
    }

    init(id: String = UUID().uuidString, content: String, post: FlutterSerializedModel) throws {
        self.model = try FlutterSerializedModel(id: UUID().uuidString, map: FlutterDataStoreRequestUtils.getJSONValue(["content": content, "team": post.toMap(modelSchema: Post3.schema)]))
    }

    init(model: FlutterSerializedModel) {
        self.model = model
    }

    init(json: String) throws {
        let data = Data(json.utf8)
        let map = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        self.model = try FlutterSerializedModel(id: map!["id"] as! String, map: FlutterDataStoreRequestUtils.getJSONValue(map!))
    }

    func setPostId(postId: String) throws {
        model.values["postID"] = JSONValue.string(postId)

    }

    func idString() -> String {
        return model.id
    }

    func id() -> JSONValue? {
        return model.values["id"]
    }

    func content() -> JSONValue? {
        return model.values["content"]
    }

    func postId() -> JSONValue? {
        return model.values["postID"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Comment3Wrapper(model: model)
        return copy
    }
}

extension Comment3Wrapper: Equatable {
    static func == (lhs: Comment3Wrapper, rhs: Comment3Wrapper) -> Bool {
        return lhs.idString() == rhs.idString()
            && lhs.postId() == rhs.postId()
            && lhs.content() == rhs.content()
    }
}
