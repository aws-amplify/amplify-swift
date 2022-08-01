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
 
 Wraps: Comment3
 */

class Comment3Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(id: String = UUID().uuidString, postID: String, content: String) throws {
        let map: [String: Any] = [
            "postID": postID,
            "content": content
        ]
        self.model = FlutterSerializedModel(id: id, map: try FlutterDataStoreRequestUtils.getJSONValue(map))
    }

    init(id: String = UUID().uuidString, content: String, post: FlutterSerializedModel) throws {
        self.model = FlutterSerializedModel(id: UUID().uuidString, map: try FlutterDataStoreRequestUtils.getJSONValue(["content": content, "team": post.toMap(modelSchema: Post3.schema)]))
    }

    init(model: FlutterSerializedModel) {
        self.model = model
    }

    init(json: String) throws {
        let data = json.data(using: .utf8)!
        let map = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        self.model = FlutterSerializedModel(id: map!["id"] as! String, map: try FlutterDataStoreRequestUtils.getJSONValue(map!))
    }

    func setPostId(postId: String) throws {
        self.model.values["postID"] = JSONValue.string(postId)

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

    func postId() -> JSONValue? {
        return self.model.values["postID"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Comment3Wrapper(model: model)
        return copy
    }
}

extension Comment3Wrapper: Equatable {
    public static func == (lhs: Comment3Wrapper, rhs: Comment3Wrapper) -> Bool {
        return lhs.idString() == rhs.idString()
            && lhs.postId() == rhs.postId()
            && lhs.content() == rhs.content()
    }
}
