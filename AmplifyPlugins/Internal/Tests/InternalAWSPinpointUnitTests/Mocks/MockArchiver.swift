//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import InternalAWSPinpoint

class MockArchiver: AmplifyArchiverBehaviour {
    var encoded: Data = .init()
    var decoded: Decodable?

    func resetCounters() {
        encodeCount = 0
        decodeCount = 0
    }

    var encodeCount = 0
    func encode(_ encodable: some Encodable) throws -> Data {
        encodeCount += 1
        return encoded
    }

    var decodeCount = 0
    func decode<T>(_ decodable: T.Type, from data: Data) throws -> T? where T: Decodable {
        decodeCount += 1
        return decoded as? T
    }
}
