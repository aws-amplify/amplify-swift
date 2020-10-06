//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

//public class DataStoreListDecoder: ListDecoder {
//    public init() { }
//    static public func shouldDecode(decoder: Decoder) -> Bool {
//        let json = try? JSONValue(from: decoder)
//        if case let .object(list) = json,
//           case .string = list["associatedId"],
//           case .string = list["associatedField"] {
//            return true
//        }
//
//        if case .array = json {
//            return true
//        }
//
//        return false
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
//            return try decoder.decode(DataStoreList<ModelType>.self, from: encodedData)
//        } catch {
//            return BaseList([ModelType]())
//        }
//    }
//}
