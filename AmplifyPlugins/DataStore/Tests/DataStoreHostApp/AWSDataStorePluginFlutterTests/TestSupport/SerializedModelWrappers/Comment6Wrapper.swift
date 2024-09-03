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

 Wraps: Comment6
 */
class Comment6Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(content: String, post: FlutterSerializedModel) throws {
        let map: [String: Any] = [
            "content": content,
            "post": post.toMap(modelSchema: Post6.schema)
        ]
        self.model = try FlutterSerializedModel(id: UUID().uuidString, map: FlutterDataStoreRequestUtils.getJSONValue(map))
    }

    init(model: FlutterSerializedModel) {
        self.model = model
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
    func post() -> JSONValue? {
        return model.values["post"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Comment6Wrapper(model: model)
        return copy
    }
}
