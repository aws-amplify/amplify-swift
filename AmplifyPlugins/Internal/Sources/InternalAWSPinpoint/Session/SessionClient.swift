//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

@_spi(InternalAWSPinpoint)
public protocol SessionClientBehaviour: AnyObject {
    var currentSession: PinpointSession { get }
    var analyticsClient: AnalyticsClientBehaviour? { get set }

    func startPinpointSession()
    func startTrackingSessions(backgroundTimeout: TimeInterval)
}

struct SessionClientConfiguration {
    let appId: String
    let uniqueDeviceId: String
}

class SessionClient: SessionClientBehaviour {
    private var session: PinpointSession

    weak var analyticsClient: AnalyticsClientBehaviour?
    private let endpointClient: EndpointClientBehaviour

    private let activityTracker: ActivityTrackerBehaviour
    private let archiver: AmplifyArchiverBehaviour
    private let configuration: SessionClientConfiguration
    private let sessionClientQueue = DispatchQueue(label: Constants.queue,
                                                   attributes: .concurrent)
    private let analyticsTaskQueue = TaskQueue<Void>()
    private let userDefaults: UserDefaultsBehaviour
    private var sessionBackgroundTimeout: TimeInterval = .zero

    init(activityTracker: ActivityTrackerBehaviour = ActivityTracker(),
         analyticsClient: AnalyticsClientBehaviour? = nil,
         archiver: AmplifyArchiverBehaviour,
         configuration: SessionClientConfiguration,
         endpointClient: EndpointClientBehaviour,
         userDefaults: UserDefaultsBehaviour) {
        self.activityTracker = activityTracker
        self.analyticsClient = analyticsClient
        self.archiver = archiver
        self.configuration = configuration
        self.endpointClient = endpointClient
        self.userDefaults = userDefaults
        session = Self.retrieveStoredSession(from: userDefaults, using: archiver) ?? .none
    }

    var currentSession: PinpointSession {
        sessionClientQueue.sync(flags: .barrier) {
            if session == .none {
                startNewSession()
            }
            return session
        }
    }

    func startPinpointSession() {
        guard analyticsClient != nil else {
            log.error("Pinpoint Analytics is disabled.")
            return
        }

        log.verbose("Starting a new Pinpoint Session")
        sessionClientQueue.sync(flags: .barrier) {
            if session != .none {
                log.verbose("There is a previous session")
                endSession(andSave: false)
            }
            startNewSession()
        }
    }

    func startTrackingSessions(backgroundTimeout: TimeInterval) {
        sessionBackgroundTimeout = backgroundTimeout
        activityTracker.backgroundTrackingTimeout = backgroundTimeout
        activityTracker.beginActivityTracking { [weak self] newState in
            guard let self else { return }
            self.log.verbose("New state received: \(newState)")
            self.sessionClientQueue.sync(flags: .barrier) {
                self.respond(to: newState)
            }
        }
    }

    private static func retrieveStoredSession(from userDefaults: UserDefaultsBehaviour,
                                              using archiver: AmplifyArchiverBehaviour) -> PinpointSession? {
        guard let sessionData = userDefaults.data(forKey: Constants.sessionKey),
              let storedSession = try? archiver.decode(PinpointSession.self, from: sessionData),
              !storedSession.sessionId.isEmpty else {
            return nil
        }

        return storedSession
    }

    private func startNewSession() {
        session = PinpointSession(appId: configuration.appId,
                                  uniqueId: configuration.uniqueDeviceId)
        saveSession()
        log.info("Session Started.")

        // Update Endpoint and record Session Start event
        analyticsTaskQueue.async { [weak self] in
            guard let self else { return }
            try? await self.endpointClient.updateEndpointProfile()
            self.log.verbose("Firing Session Event: Start")
            await self.record(eventType: Constants.Events.start)
        }
    }

    private func saveSession() {
        do {
            let sessionData = try archiver.encode(session)
            userDefaults.save(sessionData, forKey: Constants.sessionKey)
        } catch {
            log.error("Error archiving sessionData: \(error.localizedDescription)")
        }
    }

    private func pauseSession() {
        log.verbose("Attempting to pause session")
        session.pause()
        saveSession()
        log.info("Session Paused.")
        analyticsTaskQueue.async { [weak self] in
            guard let self else { return }
            self.log.verbose("Firing Session Event: Pause")
            await self.record(eventType: Constants.Events.pause)
        }
    }

    private func resumeSession() {
        log.verbose("Attempting to resume session")
        if session.isStopped {
            log.verbose("Session has been stopped. Starting a new one...")
            startNewSession()
            return
        }

        guard session.isPaused else {
            log.verbose("Session Resume Failed: Session is not paused")
            return
        }

        guard !isSessionExpired(session) else {
            log.verbose("Session has expired. Starting a fresh one...")
            endSession(andSave: false)
            startNewSession()
            return
        }

        session.resume()
        saveSession()
        log.info("Session Resumed.")
        analyticsTaskQueue.async { [weak self] in
            guard let self else { return }
            self.log.verbose("Firing Session Event: Resume")
            await self.record(eventType: Constants.Events.resume)
        }
    }

    private func endSession(andSave shouldSave: Bool = true) {
        log.verbose("Attempting to end session")
        guard !session.isStopped else {
            log.verbose("Session End Failed: Session is already stopped")
            return
        }
        session.stop()
        log.info("Session Stopped.")
        analyticsTaskQueue.async { [weak self, session] in
            guard let self = self,
                  let analyticsClient = self.analyticsClient else {
                return
            }
            self.log.verbose("Removing remote global attributes")
            await analyticsClient.removeAllRemoteGlobalAttributes()

            self.log.verbose("Updating session for existing events")
            try? await analyticsClient.update(session)

            self.log.verbose("Firing Session Event: Stop")
            await self.record(eventType: Constants.Events.stop)

            if shouldSave {
                self.saveSession()
            }
        }
    }

    private func isSessionExpired(_ session: PinpointSession) -> Bool {
        guard let stopTime = session.stopTime?.timeIntervalSince1970 else {
            return false
        }

        let now = Date().timeIntervalSince1970
        return now - stopTime > sessionBackgroundTimeout
    }

    private func record(eventType: String) async {
        guard let analyticsClient = analyticsClient else {
            log.error("Pinpoint Analytics is disabled.")
            return
        }

        let event = analyticsClient.createEvent(withEventType: eventType)
        try? await analyticsClient.record(event)
    }

    private func respond(to newState: ApplicationState) {
        switch newState {
        case .terminated:
            endSession()
    #if !os(macOS)
        case .runningInBackground(let isStale):
            if isStale {
                endSession()
                analyticsTaskQueue.async { [weak self] in
                    _ = try? await self?.analyticsClient?.submitEvents()
                }
            } else {
                pauseSession()
            }
        case .runningInForeground:
            resumeSession()
    #endif
        default:
            break
        }
    }
}

// MARK: - DefaultLogger
extension SessionClient: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.analytics.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}

extension SessionClient {
    struct Constants {
        static let sessionKey = "com.amazonaws.AWSPinpointSessionKey"
        static let queue = "com.amazonaws.Amplify.SessionClientQueue"

        struct Events {
            static let start = "_session.start"
            static let stop = "_session.stop"
            static let pause = "_session.pause"
            static let resume = "_session.resume"
        }
    }
}

extension PinpointSession {
    static var none = PinpointSession(sessionId: "InvalidId", startTime: Date(), stopTime: nil)
}
