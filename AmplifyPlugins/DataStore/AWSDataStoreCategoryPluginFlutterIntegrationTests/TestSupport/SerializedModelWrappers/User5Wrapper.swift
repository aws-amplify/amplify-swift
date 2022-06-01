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
 
 Wraps: User5
 */
class User5Wrapper: NSCopying {
    var model: FlutterSerializedModel

    init(id: String, username: String) throws {
        self.model = FlutterSerializedModel(id: id, map: try FlutterDataStoreRequestUtils.getJSONValue(["username": username]))
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

    func username() -> JSONValue? {
        return self.model.values["username"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = User5Wrapper(model: model)
        return copy
    }
}
