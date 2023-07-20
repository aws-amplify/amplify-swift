//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
#if os(watchOS)
@testable import APIWatchApp
#else
@testable import APIHostApp
#endif

extension GraphQLScalarTests {
    
    func testScalarContainerAPISwift() async throws {
        let id = UUID().uuidString
        let date = Temporal.Date.now().iso8601String
        let time = Temporal.Time.now().iso8601String
        let myDateTime = Temporal.DateTime.now().iso8601String
        let input = APISwift.CreateScalarContainerInput(
            id: id,
            myString: "myString",
            myInt: 1,
            myDouble: 1.0,
            myBool: true,
            myDate: date,
            myTime: time,
            myDateTime: myDateTime,
            myTimeStamp: 123,
            myEmail: "local-part@domain-part",
            myJson: "{}",
            myPhone: "2342355678",
            myUrl: "https://www.amazon.com/dp/B000NZW3KC/",
            myIpAddress: "123.12.34.56")
        let mutation = APISwift.CreateScalarContainerMutation(input: input)
        
        let request = GraphQLRequest(
            document: APISwift.CreateScalarContainerMutation.operationString,
            variables: mutation.variables?.jsonObject,
            responseType: APISwift.CreateScalarContainerMutation.Data.self)
        
        let data = try await mutateModel(request: request)
        guard let container = data.createScalarContainer else {
            XCTFail("Missing created container")
            return
        }
        XCTAssertEqual(container.id, id)
        XCTAssertEqual(container.myString, "myString")
        XCTAssertEqual(container.myInt, 1)
        XCTAssertEqual(container.myDouble, 1.0)
        XCTAssertEqual(container.myBool, true)
        XCTAssertEqual(container.myDate, date)
        XCTAssertEqual(container.myTime, time)
        XCTAssertEqual(container.myDateTime, myDateTime)
        XCTAssertEqual(container.myTimeStamp, 123)
        XCTAssertEqual(container.myEmail, "local-part@domain-part")
        XCTAssertEqual(container.myJson, "{}")
        XCTAssertEqual(container.myPhone, "2342355678")
        XCTAssertEqual(container.myUrl, "https://www.amazon.com/dp/B000NZW3KC/")
        XCTAssertEqual(container.myIpAddress, "123.12.34.56")
        
    }
    
    func testListIntContainerAPISwift() async throws {
        let id = UUID().uuidString
        let input = APISwift.CreateListIntContainerInput(
            id: id,
            test: 2,
            intList: [1, 2, 3],
            nullableIntList: [1, 2, 3])
        let mutation = APISwift.CreateListIntContainerMutation(input: input)
        let request = GraphQLRequest(
            document: APISwift.CreateListIntContainerMutation.operationString,
            variables: mutation.variables?.jsonObject,
            responseType: APISwift.CreateListIntContainerMutation.Data.self)
        let data = try await mutateModel(request: request)
        guard let container = data.createListIntContainer else {
            XCTFail("Missing created container")
            return
        }
        XCTAssertEqual(container.id, id)
        XCTAssertEqual(container.intList, [1, 2, 3])
        XCTAssertEqual(container.nullableIntList, [1, 2, 3])
    }
}
