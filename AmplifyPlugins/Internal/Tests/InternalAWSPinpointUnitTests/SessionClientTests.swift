//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
import XCTest
import AmplifyAsyncTesting

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
                                                                         uniqueDeviceId: "deviceId"),
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
        let expectationStartSession = AsyncExpectation(description: "Start event for new session")
        await analyticsClient.setRecordExpectation(expectationStartSession)
        let currentSession = client.currentSession
        XCTAssertFalse(currentSession.isPaused)
        XCTAssertNil(currentSession.stopTime)
        XCTAssertEqual(archiver.encodeCount, 1)
        XCTAssertEqual(activityTracker.beginActivityTrackingCount, 0)
        XCTAssertEqual(userDefaults.saveCount, 1)
        
        await waitForExpectations([expectationStartSession], timeout: 1)
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
        let expectationStartSession = AsyncExpectation(description: "Start event for new session")
        await analyticsClient.setRecordExpectation(expectationStartSession)
        client.startPinpointSession()
        await waitForExpectations([expectationStartSession], timeout: 1)
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
        let expectationStopStart = AsyncExpectation(description: "Stop event for current session and Start event for a new one")
        await analyticsClient.setRecordExpectation(expectationStopStart, count: 2)
        client.startPinpointSession()
        await waitForExpectations([expectationStopStart], timeout: 1)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 2)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 2)
        let events = await analyticsClient.recordedEvents
        XCTAssertEqual(events.count, 2)
        XCTAssertNotNil(events.first(where: { $0.eventType == SessionClient.Constants.Events.stop }))
        XCTAssertNotNil(events.first(where: { $0.eventType == SessionClient.Constants.Events.start }))
    }

#if !os(macOS)
    func testApplicationMovedToBackground_notStale_shouldSaveSession_andRecordPauseEvent() async {
        let expectationStartSession = AsyncExpectation(description: "Start event for new session")
        await analyticsClient.setRecordExpectation(expectationStartSession)
        client.startPinpointSession()
        client.startTrackingSessions(backgroundTimeout: sessionTimeout)
        await waitForExpectations([expectationStartSession], timeout: 1)
        await resetCounters()
        let expectationPauseSession = AsyncExpectation(description: "Pause event for current session")
        await analyticsClient.setRecordExpectation(expectationPauseSession)
        activityTracker.callback?(.runningInBackground(isStale: false))
        await waitForExpectations([expectationPauseSession], timeout: 1)

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
        let expectationStartSession = AsyncExpectation(description: "Start event for new session")
        client.startPinpointSession()
        client.startTrackingSessions(backgroundTimeout: sessionTimeout)
        await analyticsClient.setRecordExpectation(expectationStartSession)
        await waitForExpectations([expectationStartSession], timeout: 1)

        await resetCounters()
        let expectationStopSession = AsyncExpectation(description: "Stop event for current session")
        await analyticsClient.setRecordExpectation(expectationStopSession)
        let expectationSubmitEvents = AsyncExpectation(description: "Submit events")
        await analyticsClient.setSubmitEventsExpectation(expectationSubmitEvents)
        activityTracker.callback?(.runningInBackground(isStale: true))
        await waitForExpectations([expectationStopSession, expectationSubmitEvents], timeout: 1)

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
        let expectationStartSession = AsyncExpectation(description: "Start event for new session")
        await analyticsClient.setRecordExpectation(expectationStartSession)
        client.startPinpointSession()
        await waitForExpectations([expectationStartSession], timeout: 1)

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
        let expectationStartandPause = AsyncExpectation(description: "Start and Pause event for new session")
        await analyticsClient.setRecordExpectation(expectationStartandPause, count: 2)
        sessionTimeout = 1000
        createNewSessionClient()
        client.startPinpointSession()
        client.startTrackingSessions(backgroundTimeout: sessionTimeout)

        // First pause the session
        activityTracker.callback?(.runningInBackground(isStale: false))
        await waitForExpectations([expectationStartandPause], timeout: 1)

        await resetCounters()
        let expectationResume = AsyncExpectation(description: "Resume event for non-expired session")
        await analyticsClient.setRecordExpectation(expectationResume)
        activityTracker.callback?(.runningInForeground)
        await waitForExpectations([expectationResume], timeout: 1)

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
        let expectationStartandPause = AsyncExpectation(description: "Start and Pause event for new session")
        await analyticsClient.setRecordExpectation(expectationStartandPause, count: 2)
        sessionTimeout = 0
        createNewSessionClient()
        client.startPinpointSession()
        client.startTrackingSessions(backgroundTimeout: sessionTimeout)

        // First pause the session
        activityTracker.callback?(.runningInBackground(isStale: false))
        await waitForExpectations([expectationStartandPause], timeout: 1)

        await resetCounters()
        let expectationStopAndStart = AsyncExpectation(description: "Stop event for expired session and Start event for a new one")
        await analyticsClient.setRecordExpectation(expectationStopAndStart, count: 2)
        activityTracker.callback?(.runningInForeground)
        await waitForExpectations([expectationStopAndStart], timeout: 1)

        XCTAssertEqual(archiver.encodeCount, 1)
        XCTAssertEqual(userDefaults.saveCount, 1)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 2)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 2)
        let events = await analyticsClient.recordedEvents
        XCTAssertEqual(events.count, 2)
        XCTAssertNotNil(events.first(where: { $0.eventType == SessionClient.Constants.Events.stop }))
        XCTAssertNotNil(events.first(where: { $0.eventType == SessionClient.Constants.Events.start }))
    }
#endif
    func testApplicationTerminated_shouldRecordStopEvent() async {
        let expectationStart = AsyncExpectation(description: "Start event for new session")
        await analyticsClient.setRecordExpectation(expectationStart)
        client.startPinpointSession()
        client.startTrackingSessions(backgroundTimeout: sessionTimeout)
        await waitForExpectations([expectationStart], timeout: 1)

        await resetCounters()
        let expectationStop = AsyncExpectation(description: "Stop event for current session")
        await analyticsClient.setRecordExpectation(expectationStop)
        activityTracker.callback?(.terminated)
        await waitForExpectations([expectationStop], timeout: 1)

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
