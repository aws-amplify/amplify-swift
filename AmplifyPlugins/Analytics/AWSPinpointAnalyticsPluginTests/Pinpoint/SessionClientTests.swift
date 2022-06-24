//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin
import XCTest

class SessionClientTests: XCTestCase {
    private var client: SessionClient!

    private var activityTracker: MockActivityTracker!
    private var analyticsClient: MockAnalyticsClient!
    private var archiver: MockArchiver!
    private var endpointClient: MockEndpointClient!
    private var userDefaults: MockUserDefaults!
    private var sessionTimeout: TimeInterval = 5

    override func setUp() {
        activityTracker = MockActivityTracker()
        archiver = MockArchiver()
        userDefaults = MockUserDefaults()
        analyticsClient = MockAnalyticsClient()
        endpointClient = MockEndpointClient()

        createNewSessionClient()
    }

    override func tearDown() {
        activityTracker = nil
        archiver = nil
        userDefaults = nil
        analyticsClient = nil
        endpointClient = nil
        client = nil
    }

    func createNewSessionClient() {
        client = SessionClient(activityTracker: activityTracker,
                               analyticsClient: analyticsClient,
                               archiver: archiver,
                               configuration: SessionClientConfiguration(appId: "appId",
                                                                         uniqueDeviceId: "deviceId",
                                                                         sessionBackgroundTimeout: sessionTimeout),
                               endpointClient: endpointClient,
                               userDefaults: userDefaults)
    }

    func resetCounters() async {
        await analyticsClient.resetCounters()
        activityTracker.resetCounters()
        archiver.resetCounters()
        await endpointClient.resetCounters()
        userDefaults.resetCounters()
    }

    func storeSession(isPaused: Bool = false, isExpired: Bool = false) {
        let start = isExpired ? Date().addingTimeInterval(-sessionTimeout) : Date()
        let end: Date? = isPaused ? Date() : nil
        let savedSession = PinpointSession(sessionId: "stored", startTime: start, stopTime: end)

        userDefaults.mockedValue = Data()
        archiver.decoded = savedSession
    }

    func testRetrieveStoredSessionWithoutSavedSession() {
        XCTAssertEqual(userDefaults.dataForKeyCount, 1)
        XCTAssertEqual(archiver.decodeCount, 0)
    }

    func testRetrieveStoredSession() {
        // Validate SessionClient created without a stored Session
        XCTAssertEqual(userDefaults.dataForKeyCount, 1)
        XCTAssertEqual(archiver.decodeCount, 0)

        // Validate SessionClient created with a stored Session
        storeSession()
        createNewSessionClient()

        XCTAssertEqual(userDefaults.dataForKeyCount, 2)
        XCTAssertEqual(archiver.decodeCount, 1)
    }

    func testCurrentSession_withoutStoredSession_shouldStartNewSession() async {
        let currentSession = client.currentSession
        XCTAssertFalse(currentSession.isPaused)
        XCTAssertNil(currentSession.stopTime)
        XCTAssertEqual(archiver.encodeCount, 1)
        XCTAssertEqual(activityTracker.beginActivityTrackingCount, 0)
        XCTAssertEqual(userDefaults.saveCount, 1)
        await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
        await waitForExpectations(timeout: 1)
        let updateEndpointProfileCount = await endpointClient.updateEndpointProfileCount
        XCTAssertEqual(updateEndpointProfileCount, 1)
        let createEventCount = await analyticsClient.createEventCount
        XCTAssertEqual(createEventCount, 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 1)
    }

    func testCurrentSession_withStoredSession_shouldNotStartNewSession() async {
        storeSession()
        createNewSessionClient()

        let currentSession = client.currentSession
        XCTAssertFalse(currentSession.isPaused)
        XCTAssertNil(currentSession.stopTime)
        XCTAssertEqual(archiver.encodeCount, 0)
        XCTAssertEqual(activityTracker.beginActivityTrackingCount, 0)
        XCTAssertEqual(userDefaults.saveCount, 0)
    }

    func testValidateSession_withValidSession_andStoredSession_shouldReturnValidSession() async {
        storeSession()
        await resetCounters()
        let session = PinpointSession(sessionId: "valid", startTime: Date(), stopTime: nil)
        let retrievedSession = client.validateOrRetrieveSession(session)

        XCTAssertEqual(userDefaults.dataForKeyCount, 0)
        XCTAssertEqual(archiver.decodeCount, 0)
        XCTAssertEqual(retrievedSession.sessionId, "valid")
    }

    func testValidateSession_withInvalidSession_andStoredSession_shouldReturnStoredSession() async {
        storeSession()
        await resetCounters()
        let session = PinpointSession(sessionId: "", startTime: Date(), stopTime: nil)
        let retrievedSession = client.validateOrRetrieveSession(session)

        XCTAssertEqual(userDefaults.dataForKeyCount, 1)
        XCTAssertEqual(archiver.decodeCount, 1)
        XCTAssertEqual(retrievedSession.sessionId, "stored")
    }

    func testValidateSession_withInvalidSession_andWithoutStoredSession_shouldCreateDefaultSession() async {
        await resetCounters()
        let session = PinpointSession(sessionId: "", startTime: Date(), stopTime: nil)
        let retrievedSession = client.validateOrRetrieveSession(session)

        XCTAssertEqual(userDefaults.dataForKeyCount, 1)
        XCTAssertEqual(archiver.decodeCount, 0)
        XCTAssertEqual(retrievedSession.sessionId, PinpointSession.Constants.defaultSessionId)
    }

    func testValidateSession_withNilSession_andWithoutStoredSession_shouldCreateDefaultSession() async {
        await resetCounters()
        let retrievedSession = client.validateOrRetrieveSession(nil)

        XCTAssertEqual(userDefaults.dataForKeyCount, 1)
        XCTAssertEqual(archiver.decodeCount, 0)
        XCTAssertEqual(retrievedSession.sessionId, PinpointSession.Constants.defaultSessionId)
    }

    func testStartPinpointSession_shouldRecordStartEvent() async {
        await resetCounters()

        client.startPinpointSession()
        await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
        await waitForExpectations(timeout: 1)
        let updateEndpointProfileCount = await endpointClient.updateEndpointProfileCount
        XCTAssertEqual(updateEndpointProfileCount, 1)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 1)
        guard let event = await analyticsClient.lastRecordedEvent else {
            XCTFail("Expected recorded event")
            return
        }
        XCTAssertEqual(event.eventType, SessionClient.Constants.Events.start)
    }

    func testStartPinpointSession_withExistingSession_shouldRecordStopEvent() async {
        storeSession()
        createNewSessionClient()
        await resetCounters()

        client.startPinpointSession()
        await analyticsClient.setRecordExpectation(expectation(description: "Stop event for current session and Start event for a new one"),
                                                   count: 2)
        await waitForExpectations(timeout: 1)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 2)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 2)
        let events = await analyticsClient.recordedEvents
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.eventType, SessionClient.Constants.Events.stop)
        XCTAssertEqual(events.last?.eventType, SessionClient.Constants.Events.start)
    }

    func testApplicationMovedToBackground_notStale_shouldSaveSession_andRecordPauseEvent() async {
        client.startPinpointSession()
        await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
        await waitForExpectations(timeout: 1)

        await resetCounters()
        await analyticsClient.setRecordExpectation(expectation(description: "Pause event for current session"))
        activityTracker.callback?(.runningInBackground(isStale: false))
        await waitForExpectations(timeout: 1)

        XCTAssertEqual(archiver.encodeCount, 1)
        XCTAssertEqual(userDefaults.saveCount, 1)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 1)
        guard let event = await analyticsClient.lastRecordedEvent else {
            XCTFail("Expected recorded event")
            return
        }
        XCTAssertEqual(event.eventType, SessionClient.Constants.Events.pause)
    }

    func testApplicationMovedToBackground_stale_shouldRecordStopEvent_andSubmit() async {
        client.startPinpointSession()
        await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
        await waitForExpectations(timeout: 1)

        await resetCounters()
        await analyticsClient.setRecordExpectation(expectation(description: "Stop event for current session"))
        await analyticsClient.setSubmitEventsExpectation(expectation(description: "Submit events"))
        activityTracker.callback?(.runningInBackground(isStale: true))
        await waitForExpectations(timeout: 1)

        XCTAssertEqual(archiver.encodeCount, 0)
        XCTAssertEqual(userDefaults.saveCount, 0)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 1)
        guard let event = await analyticsClient.lastRecordedEvent else {
            XCTFail("Expected recorded event")
            return
        }
        XCTAssertEqual(event.eventType, SessionClient.Constants.Events.stop)
        let submitCount = await analyticsClient.submitEventsCount
        XCTAssertEqual(submitCount, 1)
    }

    func testApplicationMovedToForeground_withNonPausedSession_shouldDoNothing() async {
        client.startPinpointSession()
        await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
        await waitForExpectations(timeout: 1)

        await resetCounters()
        activityTracker.callback?(.runningInForeground)
        XCTAssertEqual(archiver.encodeCount, 0)
        XCTAssertEqual(userDefaults.saveCount, 0)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 0)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 0)
        let event = await analyticsClient.lastRecordedEvent
        XCTAssertNil(event)
    }

    func testApplicationMovedToForeground_withNonExpiredSession_shouldRecordResumeEvent() async {
        sessionTimeout = 1000
        createNewSessionClient()
        client.startPinpointSession()

        // First pause the session
        activityTracker.callback?(.runningInBackground(isStale: false))
        await analyticsClient.setRecordExpectation(expectation(description: "Start and Pause event for new session"), count: 2)
        await waitForExpectations(timeout: 1)

        await resetCounters()
        await analyticsClient.setRecordExpectation(expectation(description: "Resume event for non-expired session"))
        activityTracker.callback?(.runningInForeground)
        await waitForExpectations(timeout: 1)

        XCTAssertEqual(archiver.encodeCount, 1)
        XCTAssertEqual(userDefaults.saveCount, 1)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 1)
        guard let event = await analyticsClient.lastRecordedEvent else {
            XCTFail("Expected recorded event")
            return
        }
        XCTAssertEqual(event.eventType, SessionClient.Constants.Events.resume)
    }

    func testApplicationMovedToForeground_withExpiredSession_shouldStartNewSession() async {
        sessionTimeout = 0
        createNewSessionClient()
        client.startPinpointSession()

        // First pause the session
        activityTracker.callback?(.runningInBackground(isStale: false))
        await analyticsClient.setRecordExpectation(expectation(description: "Start and Pause event for new session"), count: 2)
        await waitForExpectations(timeout: 1)

        await resetCounters()
        await analyticsClient.setRecordExpectation(expectation(description: "Stop event for expired session and Start event for a new one"),
                                                   count: 2)
        activityTracker.callback?(.runningInForeground)
        await waitForExpectations(timeout: 1)

        XCTAssertEqual(archiver.encodeCount, 1)
        XCTAssertEqual(userDefaults.saveCount, 1)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 2)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 2)
        let events = await analyticsClient.recordedEvents
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.eventType, SessionClient.Constants.Events.stop)
        XCTAssertEqual(events.last?.eventType, SessionClient.Constants.Events.start)
    }

    func testApplicationTerminated_shouldRecordStopEvent() async {
        client.startPinpointSession()
        await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
        await waitForExpectations(timeout: 1)

        await resetCounters()
        await analyticsClient.setRecordExpectation(expectation(description: "Stop event for current session"))
        activityTracker.callback?(.terminated)
        await waitForExpectations(timeout: 1)

        XCTAssertEqual(archiver.encodeCount, 0)
        XCTAssertEqual(userDefaults.saveCount, 0)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 1)
        guard let event = await analyticsClient.lastRecordedEvent else {
            XCTFail("Expected recorded event")
            return
        }
        XCTAssertEqual(event.eventType, SessionClient.Constants.Events.stop)
        let submitCount = await analyticsClient.submitEventsCount
        XCTAssertEqual(submitCount, 0)
    }
}
