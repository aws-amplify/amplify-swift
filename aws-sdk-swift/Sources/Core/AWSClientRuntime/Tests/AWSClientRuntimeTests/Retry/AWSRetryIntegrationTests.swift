//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import SmithyHTTPAuthAPI
import SmithyReadWrite
import SmithyXML
import XCTest
import SmithyRetriesAPI
import SmithyTestUtil
@testable import SmithyRetries
@testable import ClientRuntime
@testable import AWSClientRuntime

// This test class reproduces the "Standard Mode" test cases defined in "Retry Behavior 2.0"
// It is essentially a copy of the class of the same name in smithy-swift, but this one
// also tests AmzSdkInvocationIdMiddleware and AmzSdkRequestMiddleware.
final class RetryIntegrationTests: XCTestCase {
    private let partitionID = "partition"

    private var context: Context!
    private var next: TestOutputHandler!
    private var subject: DefaultRetryStrategy!

    private var builder: OrchestratorBuilder<TestInput, TestOutputResponse, HTTPRequest, HTTPResponse>!
    private var quota: RetryQuota { get async { await subject.quotaRepository.quota(partitionID: partitionID) } }

    private func setUp(availableCapacity: Int, maxCapacity: Int, maxRetriesBase: Int, maxBackoff: TimeInterval) async {
        // Setup the HTTP context, used by the retry middleware
        context = Context(attributes: Attributes())
        context.partitionID = partitionID
        context.socketTimeout = 60.0
        context.estimatedSkew = 30.0

        // Create the test output handler, which is the "next" middleware called by the retry middleware
        next = TestOutputHandler()

        // Create a backoff strategy with custom max backoff and no randomization
        let backoffStrategyOptions = ExponentialBackoffStrategyOptions(jitterType: .default, backoffScaleValue: 0.025, maxBackoff: maxBackoff)
        var backoffStrategy = ExponentialBackoffStrategy(options: backoffStrategyOptions)
        backoffStrategy.random = { 1.0 }

        // Create a retry strategy with custom backoff strategy & custom max retries & custom capacity
        let retryStrategyOptions = RetryStrategyOptions(backoffStrategy: backoffStrategy, maxRetriesBase: maxRetriesBase, availableCapacity: availableCapacity, maxCapacity: maxCapacity)
        subject = DefaultRetryStrategy(options: retryStrategyOptions)
        // Replace the retry strategy's sleeper with a mock, to allow tests to run without delay and for us to
        // check the delay time
        // Treat nil and 0.0 time the same (change 0.0 to nil)
        subject.sleeper = { self.next.actualDelay = ($0 != 0.0) ? $0 : nil }

        builder = TestOrchestrator.httpBuilder()
            .attributes(context)
            .retryErrorInfoProvider(DefaultRetryErrorInfoProvider.errorInfo(for:))
            .retryStrategy(subject)
            .deserialize({ _, _ in TestOutputResponse() })
            .executeRequest(next)
        builder.interceptors.add(AmzSdkInvocationIdMiddleware())
        builder.interceptors.add(AmzSdkRequestMiddleware(maxRetries: subject.options.maxRetriesBase))

        // Set the quota on the test output handler so it can verify state during tests
        next.quota = await quota
    }

    // MARK: - Standard mode

    func test_case1() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 495, delay: 1.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 490, delay: 2.0),
            TestStep(response: .success, expectedOutcome: .success, retryQuota: 495, delay: nil)
        ]
        try await runTest()
    }

    func test_case2() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(502), expectedOutcome: .retryRequest, retryQuota: 495, delay: 1.0),
            TestStep(response: .httpError(502), expectedOutcome: .retryRequest, retryQuota: 490, delay: 2.0),
            TestStep(response: .httpError(502), expectedOutcome: .maxAttemptsExceeded, retryQuota: 490, delay: nil)
        ]
        try await runTest()
    }

    func test_case3() async throws {
        await setUp(availableCapacity: 5, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 0, delay: 1.0),
            TestStep(response: .httpError(502), expectedOutcome: .retryQuotaExceeded, retryQuota: 0, delay: nil)
        ]
        try await runTest()
    }

    func test_case4() async throws {
        await setUp(availableCapacity: 0, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryQuotaExceeded, retryQuota: 0, delay: nil),
        ]
        try await runTest()
    }

    func test_case5() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 4, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 495, delay: 1.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 490, delay: 2.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 485, delay: 4.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 480, delay: 8.0),
            TestStep(response: .httpError(500), expectedOutcome: .maxAttemptsExceeded, retryQuota: 480, delay: nil)
        ]
        try await runTest()
    }

    func test_case6() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 4, maxBackoff: 3.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 495, delay: 1.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 490, delay: 2.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 485, delay: 3.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 480, delay: 3.0),
            TestStep(response: .httpError(500), expectedOutcome: .maxAttemptsExceeded, retryQuota: 480, delay: nil)
        ]
        try await runTest()
    }

    private func runTest() async throws {
        do {
            _ = try await builder.build().execute(input: TestInput())
        } catch {
            next.finalError = error
        }
        try await next.verifyResult()
    }

    // Test getTTLutility method.
    func test_getTTL() {
        let nowDateString = "Mon, 15 Jul 2024 01:24:12 GMT"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let nowDate: Date = dateFormatter.date(from: nowDateString)!

        // The two timeintervals below add up to 34  minutes 59 seconds, rounding to closest second.
        let estimatedSkew = 2039.34
        let socketTimeout = 60.0

        // Verify calculated TTL is nowDate + (34 minutes and 59 seconds).
        let ttl = awsGetTTL(now: nowDate, estimatedSkew: estimatedSkew, socketTimeout: socketTimeout)
        XCTAssertEqual(ttl, "20240715T015911Z")
    }
}

private struct TestStep {

    enum Response: Equatable {
        case success
        case httpError(Int)
    }

    enum Outcome: Equatable {
        case retryRequest
        case success
        case maxAttemptsExceeded
        case retryQuotaExceeded
    }

    let response: Response
    let expectedOutcome: Outcome
    let retryQuota: Int
    let delay: TimeInterval?
    let file: StaticString
    let line: UInt

    init(response: Response, expectedOutcome: Outcome, retryQuota: Int, delay: TimeInterval?, file: StaticString = #file, line: UInt = #line) {
        self.response = response
        self.expectedOutcome = expectedOutcome
        self.retryQuota = retryQuota
        self.delay = delay
        self.file = file
        self.line = line
    }
}

private struct TestInput {}

private struct TestOutputResponse {
    init() {}
}

private enum TestOutputError {
    static func httpError(from httpResponse: HTTPResponse) async throws -> Error  {
        RetryIntegrationTestError.dontCallThisMethod  // is never called
    }
}

private class TestOutputHandler: ExecuteRequest {
    typealias RequestType = HTTPRequest
    typealias ResponseType = HTTPResponse

    var index = 0
    fileprivate var testSteps = [TestStep]()
    private var latestTestStep: TestStep?
    var quota: RetryQuota!
    var actualDelay: TimeInterval?
    var finalError: Error?
    var invocationID = ""
    var prevAttemptNum = 0

    func execute(request: HTTPRequest, attributes: Context) async throws -> HTTPResponse {
        if index == testSteps.count { throw RetryIntegrationTestError.maxAttemptsExceeded }

        // Verify the results of the previous test step, if there was one.
        try await verifyResult(atEnd: false)
        // Verify the input's retry information headers.
        try await verifyInput(input: request)

        // Get the latest test step, then advance the index.
        let testStep = testSteps[index]
        latestTestStep = testStep
        index += 1

        // Return either a successful response or a HTTP error, depending on the directions in the test step.
        switch testStep.response {
        case .success:
            return HTTPResponse()
        case .httpError(let statusCode):
            throw TestHTTPError(statusCode: statusCode)
        }
    }

    func verifyResult(atEnd: Bool = true) async throws {
        guard let testStep = latestTestStep else {
            if atEnd {
                XCTFail("No test steps were run! Encountered error: \(String(describing: finalError!))")
            }
            return
        }

        // Test available capacity
        let availableCapacity = await quota.availableCapacity
        XCTAssertEqual(testStep.retryQuota, availableCapacity)

        // Test delay
        XCTAssertEqual(testStep.delay, actualDelay, file: testStep.file, line: testStep.line)
        actualDelay = nil

        // When called after all test steps have been performed, this
        // logic will verify that the last test step had the expected result.
        guard atEnd else { return }
        switch testStep.expectedOutcome {
        case .success:
            if let error = finalError { XCTFail("Unexpected error: \(error)", file: testStep.file, line: testStep.line) }
        case .retryQuotaExceeded, .maxAttemptsExceeded:
            if !(finalError is TestHTTPError) { XCTFail("Test did not end on service error", file: testStep.file, line: testStep.line) }
        case .retryRequest:
            XCTFail("Test should not end on retry", file: testStep.file, line: testStep.line)
        }
    }

    func verifyInput(input: HTTPRequest) async throws {
        // Get invocation ID of the request off of amz-sdk-invocation-id header.
        let invocationID = try XCTUnwrap(input.headers.value(for: "amz-sdk-invocation-id"))
        // If this is the first request, save the retrieved ID.
        if (self.invocationID.isEmpty) { self.invocationID = invocationID }

        // Retrieved IDs from all requests under a same call must be the same.
        XCTAssertEqual(self.invocationID, invocationID)

        // Get retry information off of amz-sdk-request header.
        let amzSdkRequestHeaderValue = try XCTUnwrap(input.headers.value(for: "amz-sdk-request"))

        // Extract request pair values from amz-sdk-request header value.
        let requestPairs = amzSdkRequestHeaderValue.components(separatedBy: "; ")
        var ttl: String = ""
        let attemptNum: Int = try XCTUnwrap(
            Int(
                try XCTUnwrap(requestPairs.first { $0.hasPrefix("attempt=") })
                    .components(separatedBy: "=")[1]
            )
        )
        _ = try XCTUnwrap(
            Int(
                try XCTUnwrap(requestPairs.first { $0.hasPrefix("max=") })
                    .components(separatedBy: "=")[1]
            )
        )
        // For attempts 2+, TTL must be present.
        if (attemptNum > 1) {
            ttl = try XCTUnwrap(requestPairs.first { $0.hasPrefix("ttl") }).components(separatedBy: "=")[1]
            // Check that TTL date is in strftime format.
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            XCTAssertNotNil(dateFormatter.date(from: ttl))
        }

        // Verify attempt number was incremented by 1 from previous request.
        XCTAssertEqual(attemptNum, (self.prevAttemptNum + 1))
        self.prevAttemptNum = attemptNum
    }
}

// Thrown during a test to simulate a server response with a given HTTP status code.
private struct TestHTTPError: HTTPError, Error {
    var httpResponse: HTTPResponse

    init(statusCode: Int) {
        guard let statusCodeValue = HTTPStatusCode(rawValue: statusCode) else { fatalError("Unrecognized HTTP code") }
        self.httpResponse = HTTPResponse(statusCode: statusCodeValue)
    }
}

// These errors are thrown when a test fails.
private enum RetryIntegrationTestError: Error {
    case dontCallThisMethod
    case noRemainingTestSteps
    case maxAttemptsExceeded
    case unexpectedSuccess
    case unexpectedFailure
}
