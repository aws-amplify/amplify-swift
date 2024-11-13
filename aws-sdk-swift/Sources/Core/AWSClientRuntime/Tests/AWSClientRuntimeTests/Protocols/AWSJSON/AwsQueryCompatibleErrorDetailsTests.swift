import XCTest
import AWSClientRuntime

class AwsQueryCompatibleErrorDetailsTests: XCTestCase {

    func testParseMalformed() {
        XCTAssertThrowsError(try AwsQueryCompatibleErrorDetails.parse("malformed")) { error in
            XCTAssertEqual((error as! ParseError).debugDescription, "value is malformed")
        }
    }

    func testParseEmptyCode() {
        XCTAssertThrowsError(try AwsQueryCompatibleErrorDetails.parse(";type")) { error in
            XCTAssertEqual((error as! ParseError).debugDescription, "code is empty")
        }
    }

    func testParseEmptyType() {
        XCTAssertThrowsError(try AwsQueryCompatibleErrorDetails.parse("code;")) { error in
            XCTAssertEqual((error as! ParseError).debugDescription, "type is empty")
        }
    }

    func testParseErrorClient() throws {
        let expected = AwsQueryCompatibleErrorDetails(
            code: "com.test.ErrorCode",
            type: "Sender"
        )
        let actual = try AwsQueryCompatibleErrorDetails.parse("com.test.ErrorCode;Sender")
        XCTAssertEqual(expected.code, actual.code)
        XCTAssertEqual(expected.type, actual.type)
    }

    func testParseErrorServer() throws {
        let expected = AwsQueryCompatibleErrorDetails(
            code: "com.test.ErrorCode",
            type: "Receiver"
        )
        let actual = try AwsQueryCompatibleErrorDetails.parse("com.test.ErrorCode;Receiver")
        XCTAssertEqual(expected.code, actual.code)
        XCTAssertEqual(expected.type, actual.type)
    }
}
