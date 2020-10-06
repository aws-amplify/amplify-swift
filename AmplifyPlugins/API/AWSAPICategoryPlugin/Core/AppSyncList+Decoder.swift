//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
//
//public class AppSyncListDecoder: ListDecoder {
//
//    static public func shouldDecode(decoder: Decoder) -> Bool {
//        let json = try? JSONValue(from: decoder)
//
//        if case let .object(jsonObject) = json,
//           case .array = jsonObject["items"] {
//            return true
//        }
//
//        do {
//            _ = try AppSyncListPayload.init(from: decoder)
//            return true
//        } catch {
//            return false
//        }
//    }
//
//    static public func decode<ModelType: Model>(decoder: Decoder, modelType: ModelType.Type) -> BaseList<ModelType> {
//        let json = try? JSONValue(from: decoder)
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
//        let encoder = JSONEncoder()
//        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
//
//        do {
//            let encodedData = try encoder.encode(json)
//            return try decoder.decode(AppSyncList<ModelType>.self, from: encodedData)
//        } catch {
//            return BaseList([ModelType]())
//        }
//    }
//}
