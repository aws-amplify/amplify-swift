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
        self.model = try FlutterSerializedModel(id: id, map: FlutterDataStoreRequestUtils.getJSONValue(map))
    }

    init(model: FlutterSerializedModel) {
        self.model = model
    }

    init(json: String) throws {
        let data = Data(json.utf8)
        let map = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        self.model = try FlutterSerializedModel(id: map!["id"] as! String, map: FlutterDataStoreRequestUtils.getJSONValue(map!))
    }

    init(post: Post) throws {
        let map: [String: Any] = [
            "title": post.title,
            "content": post.content,
            "createdAt": post.createdAt.iso8601String,
            "rating": post.rating
        ]
        self.model = try FlutterSerializedModel(id: post.id, map: FlutterDataStoreRequestUtils.getJSONValue(map))
    }

    func updateRating(rating: Double) throws {
        var map = model.values
        map["rating"] = JSONValue.init(floatLiteral: rating)
        model = FlutterSerializedModel(id: model.id, map: map)
    }

    func updateStringProp(key: String, value: String) throws {
        var map = model.values
        map[key] = JSONValue.string(value)
        model = FlutterSerializedModel(id: model.id, map: map)
    }

    func idString() -> String {
        return model.id
    }

    func id() -> JSONValue? {
        return model.values["id"]
    }

    func title() -> JSONValue? {
        return model.values["title"]
    }

    func rating() -> JSONValue? {
        return model.values["rating"]
    }

    func content() -> JSONValue? {
        return model.values["content"]
    }

    func createdAt() -> JSONValue? {
        return model.values["createdAt"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = PostWrapper(model: model)
        return copy
    }
}

extension PostWrapper: Equatable {
    static func == (lhs: PostWrapper, rhs: PostWrapper) -> Bool {
        return lhs.idString() == rhs.idString()
            && lhs.title() == rhs.title()
            && lhs.rating() == rhs.rating()
            && lhs.content() == rhs.content()
            && lhs.createdAt() == rhs.createdAt()
    }
}
