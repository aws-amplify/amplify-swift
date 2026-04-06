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
 Wraps: Post3
 */
class Post3Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(id: String = UUID().uuidString, title: String, comments: [FlutterSerializedModel] = []) throws {
        var serializedComments = [[:]]

        for comment in comments {
            serializedComments.append(comment.toMap(modelSchema: Comment3.schema))
        }

        var map: [String: Any] = [
            "title": title
        ]

        if !serializedComments.isEmpty {
            map["comments"] = serializedComments
        }
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

    func idString() -> String {
        return model.id
    }

    func id() -> JSONValue? {
        return model.values["id"]
    }

    func title() -> JSONValue? {
        return model.values["title"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Post3Wrapper(model: model)
        return copy
    }
}

extension Post3Wrapper: Equatable {
    static func == (lhs: Post3Wrapper, rhs: Post3Wrapper) -> Bool {
        return lhs.idString() == rhs.idString()
            && lhs.title() == rhs.title()
    }
}
