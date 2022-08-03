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

        if serializedComments.count > 0 {
            map["comments"] = serializedComments
        }
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

    func idString() -> String {
        return self.model.id
    }

    func id() -> JSONValue? {
        return self.model.values["id"]
    }

    func title() -> JSONValue? {
        return self.model.values["title"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Post3Wrapper(model: model)
        return copy
    }
}

extension Post3Wrapper: Equatable {
    public static func == (lhs: Post3Wrapper, rhs: Post3Wrapper) -> Bool {
        return lhs.idString() == rhs.idString()
            && lhs.title() == rhs.title()
    }
}
