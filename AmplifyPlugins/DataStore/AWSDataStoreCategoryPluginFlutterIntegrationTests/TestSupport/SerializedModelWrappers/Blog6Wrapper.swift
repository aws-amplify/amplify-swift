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
 
 Wraps: Blog6
 */
class Blog6Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(name: String) throws {
        let map: [String: Any] = [
            "name": name
        ]
        self.model = FlutterSerializedModel(id: UUID().uuidString, map: try FlutterDataStoreRequestUtils.getJSONValue(map))
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

    func name() -> JSONValue? {
        return self.model.values["name"]
    }

    func posts() -> JSONValue? {
        return self.model.values["posts"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Blog6Wrapper(model: model)
        return copy
    }
}
