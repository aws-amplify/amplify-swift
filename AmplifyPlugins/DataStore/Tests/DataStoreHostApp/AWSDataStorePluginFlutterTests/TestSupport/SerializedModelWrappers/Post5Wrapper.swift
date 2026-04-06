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

 Wraps: Post5
 */
class Post5Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(id: String = UUID().uuidString, title: String) throws {
        let map: [String: Any] = [
            "title": title
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

    func idString() -> String {
        return model.id
    }

    func id() -> JSONValue? {
        return model.values["id"]
    }

    func title() -> JSONValue? {
        return model.values["title"]
    }

    func editors() -> JSONValue? {
        return model.values["editors"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Post5Wrapper(model: model)
        return copy
    }
}
