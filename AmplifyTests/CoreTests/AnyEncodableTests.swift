//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

private struct EncodableStruct: Encodable {

    let id: String
    let name: String
    let number: Int

}

class AnyEncodableTests: XCTestCase {

    /// - Given: a struct that comforms to `Encodable`
    /// - When:
    ///   - the it's encoded using a `JSONEncoder`
    /// - Then:
    ///   - the encoded result of the struct and the `eraseToAnyEncodable()` must match
    func testAnyEncodableOutput() {
        let encodableStruct = EncodableStruct(id: "id", name: "name", number: 10)
        let encodable: Encodable = encodableStruct as Encodable

        let jsonEncoder = JSONEncoder()
        do {
            let encodableStructData = try jsonEncoder.encode(encodableStruct)
            let anyEncodableStructData = try jsonEncoder.encode(encodable.eraseToAnyEncodable())

            XCTAssertEqual(encodableStructData, anyEncodableStructData)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
