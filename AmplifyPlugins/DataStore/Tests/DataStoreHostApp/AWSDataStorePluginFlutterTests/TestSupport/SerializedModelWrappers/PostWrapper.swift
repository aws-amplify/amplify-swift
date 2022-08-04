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
 
 Wraps: Post
 */
class PostWrapper: NSCopying {
    var model: FlutterSerializedModel

    init(id: String = UUID().uuidString, title: String, content: String, createdAt: String = Temporal.DateTime.now().iso8601String, rating: Double = 1) throws {
        let map: [String: Any] = [
            "title": title,
            "content": content,
            "createdAt": createdAt,
            "rating": rating
        ]
        self.model = FlutterSerializedModel(id: id, map: try FlutterDataStoreRequestUtils.getJSONValue(map))
    }

    init(model: FlutterSerializedModel) {
        self.model = model
    }

    init(json: String) throws {
        let data = json.data(using: .utf8)!
        let map = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        self.model = FlutterSerializedModel(id: map!["id"] as! String, map: try FlutterDataStoreRequestUtils.getJSONValue(map!))
    }

    init(post: Post) throws {
        let map: [String: Any] = [
            "title": post.title,
            "content": post.content,
            "createdAt": post.createdAt.iso8601String,
            "rating": post.rating
        ]
        self.model = FlutterSerializedModel(id: post.id, map: try FlutterDataStoreRequestUtils.getJSONValue(map))
    }

    func updateRating(rating: Double) throws {
        var map = self.model.values
        map["rating"] = JSONValue.init(floatLiteral: rating)
        self.model = FlutterSerializedModel(id: self.model.id, map: map)
    }

    func updateStringProp(key: String, value: String) throws {
        var map = self.model.values
        map[key] = JSONValue.string(value)
        self.model = FlutterSerializedModel(id: self.model.id, map: map)
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

    func rating() -> JSONValue? {
        return self.model.values["rating"]
    }

    func content() -> JSONValue? {
        return self.model.values["content"]
    }

    func createdAt() -> JSONValue? {
        return self.model.values["createdAt"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = PostWrapper(model: model)
        return copy
    }
}

extension PostWrapper: Equatable {
    public static func == (lhs: PostWrapper, rhs: PostWrapper) -> Bool {
        return lhs.idString() == rhs.idString()
            && lhs.title() == rhs.title()
            && lhs.rating() == rhs.rating()
            && lhs.content() == rhs.content()
            && lhs.createdAt() == rhs.createdAt()
    }
}
