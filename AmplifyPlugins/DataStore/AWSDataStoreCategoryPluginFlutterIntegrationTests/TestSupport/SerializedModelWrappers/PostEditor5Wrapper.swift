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
 
 Wraps: PostEditor5
 */
class PostEditor5Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(post: FlutterSerializedModel, editor: FlutterSerializedModel) throws {
        self.model = FlutterSerializedModel(id: UUID().uuidString, map: try FlutterDataStoreRequestUtils.getJSONValue(["post": post.toMap(modelSchema: Post5.schema), "editor": editor.toMap(modelSchema: User5.schema)]))
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

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = PostEditor5Wrapper(model: model)
        return copy
    }
}
