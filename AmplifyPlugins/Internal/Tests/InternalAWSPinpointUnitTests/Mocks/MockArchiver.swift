//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import InternalAWSPinpoint
import Foundation

class MockArchiver: AmplifyArchiverBehaviour {
    var encoded: Data = Data()
    var decoded: Decodable?

    func resetCounters() {
        encodeCount = 0
        decodeCount = 0
    }

    var encodeCount = 0
    func encode<T>(_ encodable: T) throws -> Data where T: Encodable {
        encodeCount += 1
        return encoded
    }

    var decodeCount = 0
    func decode<T>(_ decodable: T.Type, from data: Data) throws -> T? where T: Decodable {
        decodeCount += 1
        return decoded as? T
    }
}
