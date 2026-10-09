//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API takes. XCTest runs one test at a time.
final class AWSAuthSignInTaskStateOrderTests: XCTestCase, @unchecked Sendable {

    private var capture: CapturingLoggingPlugin!
    private var savedPlugins: [PluginKey: LoggingCategoryPlugin] = [:]
    private var savedLogLevel: LogLevel = .error
    private var savedRouter: (any EngineLogRouter)?

    override func setUp() {
        capture = CapturingLoggingPlugin()
        savedPlugins = Amplify.Logging.plugins
        savedLogLevel = Amplify.Logging.logLevel
        savedRouter = EngineLog.router
        Amplify.Logging.plugins = [capture.key: capture]
        Amplify.Logging.logLevel = .verbose
        // `UserPoolSignInHelper` logs through the global engine router.
        EngineLog.install(AmplifyEngineLogRouter())
    }

    override func tearDown() {
        capture.onRecord(nil)
        Amplify.Logging.plugins = savedPlugins
        Amplify.Logging.logLevel = savedLogLevel
        if let savedRouter {
            EngineLog.install(savedRouter)
        }
    }

    /// Test that the sign-in task sees the first state its sign-in event leads to
    ///
    /// - Given: A signed-out state machine with a mocked SRP sign-in, and a log hook that holds the sign-in
    ///   task, right after it has sent its sign-in event, until the flow has moved past
    ///   `signingIn(.notStarted)`
    /// - When:
    ///    - The sign-in task runs
    /// - Then:
    ///    - Sign-in succeeds, and the task checked the next step for `signingIn(.notStarted)`: it
    ///      subscribed to the state machine before sending the event, so it saw that state however fast
    ///      the flow's first action ran
    ///
    /// The hold has to block: between sending and listening the task has no suspension point that a test
    /// controls, and `listen()` switches onto a free actor without suspending. So the task runs on a serial
    /// queue of its own (a task executor preference) and only that queue's thread is blocked. The flow's
    /// actions run on detached tasks, on the cooperative pool, which stays free even when it is one thread
    /// wide (`LIBDISPATCH_COOPERATIVE_POOL_STRICT=1`). The hook refuses to block any other thread.
    ///
    func testSignInSeesTheFirstSigningInStateHoweverFastTheFlowMovesOn() async throws {
        guard #available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) else {
            throw XCTSkip("Needs task executor preferences")
        }
        let executor = SerialQueueTaskExecutor(label: "AWSAuthSignInTaskStateOrderTests.signInTask")
        let leftNotStarted = DispatchSemaphore(value: 0)
        let stateMachine = makeStateMachine { oldState, newState in
            guard case .configured(.signingIn(.notStarted), _, _) = oldState,
                  case .configured(.signingIn(let signInState), _, _) = newState,
                  signInState != .notStarted
            else {
                return
            }
            leftNotStarted.signal()
        }
        let heldOnItsOwnQueue = TestBox(false)
        capture.onRecord { line in
            // The sign-in task logs this after sending its event and before it looks at any state.
            guard line.message == "Waiting for signin to complete" else {
                return
            }
            guard executor.isCurrent else {
                XCTFail("The sign-in task is not on its own queue; not blocking a shared thread")
                return
            }
            heldOnItsOwnQueue.set(true)
            XCTAssertEqual(leftNotStarted.wait(timeout: .now() + 10), .success, "The flow never left notStarted")
        }
        let task = AWSAuthSignInTask(
            AuthSignInRequest(
                username: "username",
                password: "password",
                options: AuthSignInRequest.Options(pluginOptions: AWSAuthSignInOptions(authFlowType: .userSRP))
            ),
            authStateMachine: stateMachine,
            configuration: Defaults.makeDefaultAuthConfigData()
        )

        let result = try await withTaskExecutorPreference(executor) {
            try await task.value
        }

        XCTAssertTrue(result.isSignedIn)
        XCTAssertTrue(heldOnItsOwnQueue.get(), "The sign-in task was never held")
        XCTAssertTrue(
            capture.lines.contains { $0.message == "Checking next step for: notStarted" },
            "The sign-in task never saw signingIn(.notStarted)"
        )
    }

    private func makeStateMachine(
        onResolve: @escaping @Sendable (_ oldState: AuthState, _ newState: AuthState) -> Void
    ) -> AuthStateMachine {
        let userPool = MockIdentityProvider(
            mockInitiateAuthResponse: { _ in
                InitiateAuthOutput(
                    authenticationResult: .none,
                    challengeName: .passwordVerifier,
                    challengeParameters: InitiateAuthOutput.validChalengeParams,
                    session: "someSession"
                )
            },
            mockRespondToAuthChallengeResponse: { _ in
                RespondToAuthChallengeOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""
                    ),
                    challengeName: .none,
                    challengeParameters: [:],
                    session: "session"
                )
            }
        )
        let environment = Defaults.makeDefaultAuthEnvironment(userPoolFactory: { userPool })
        return AuthStateMachine(
            resolver: TrackingResolver(AuthState.Resolver(logger: AmplifyEngineLogRouter()), activity: MachineActivity(), onResolve: onResolve),
            environment: environment,
            initialState: .configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)
        )
    }
}

/// Runs the jobs of the tasks that prefer it on one serial dispatch queue, so blocking one of them blocks
/// that queue's thread and never a thread of the cooperative pool.
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private final class SerialQueueTaskExecutor: TaskExecutor, @unchecked Sendable {

    private let queue: DispatchQueue
    private let key = DispatchSpecificKey<Void>()

    init(label: String) {
        self.queue = DispatchQueue(label: label)
        queue.setSpecific(key: key, value: ())
    }

    /// Whether the caller runs on this executor's queue.
    var isCurrent: Bool {
        DispatchQueue.getSpecific(key: key) != nil
    }

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedTaskExecutor()
        queue.async {
            job.runSynchronously(on: executor)
        }
    }
}
