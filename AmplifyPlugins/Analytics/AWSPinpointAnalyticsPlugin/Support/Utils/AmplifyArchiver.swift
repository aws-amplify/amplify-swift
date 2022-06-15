//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AmplifyArchiverBehaviour {
  func encode<T>(_ encodable: T) throws -> Data where T: Encodable
  func decode<T>(_ decodable: T.Type, from data: Data) throws -> T? where T: Decodable
}

struct AmplifyArchiver: AmplifyArchiverBehaviour {
  func encode<T>(_ encodable: T) throws -> Data where T: Encodable {
    let archiver = NSKeyedArchiver(requiringSecureCoding: false)
    try archiver.encodeEncodable(encodable, forKey: NSKeyedArchiveRootObjectKey)
    archiver.finishEncoding()
    return archiver.encodedData
  }

  func decode<T>(_ decodable: T.Type, from data: Data) throws -> T? where T: Decodable {
    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
    return try unarchiver.decodeTopLevelDecodable(decodable, forKey: NSKeyedArchiveRootObjectKey)
  }
}
