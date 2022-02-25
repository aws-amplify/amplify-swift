//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify

public class FlutterDataStoreRequestUtils {
    
    static func getJSONValue(_ jsonDict: [String: Any]) throws -> [String: JSONValue] {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict) else {
            throw DataStoreError.decodingError("Unable to deserialize json data", "Check the model structure.")
        }
        guard let jsonValue = try? JSONDecoder().decode(Dictionary<String, JSONValue>.self,
                                                        from: jsonData) else {
            throw DataStoreError.decodingError("Unable to decode json value", "Check the model structure.")
        }
        return jsonValue
    }
}
