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

 Wraps: User5
 */
class User5Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(id: String, username: String) throws {
        self.model = try FlutterSerializedModel(id: id, map: FlutterDataStoreRequestUtils.getJSONValue(["username": username]))
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

    func username() -> JSONValue? {
        return model.values["username"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = User5Wrapper(model: model)
        return copy
    }
}
