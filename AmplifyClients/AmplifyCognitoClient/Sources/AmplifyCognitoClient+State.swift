//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// What this session is, right now.
    ///
    /// A verb rather than a property, because it can wait for the saved session to be restored. It then
    /// answers from memory, without reading storage again, so a change another process makes shows up on
    /// this session's next read of its record. It never throws: a storage failure is
    /// `.unavailable(reason)` — never `.signedOut` — and anything unrecoverable is `.failed`. A caller whose
    /// task is cancelled while the restore is waited for gets `.unavailable(.interrupted)`: nothing was
    /// learned about storage, and the restore carries on for the session.
    ///
    /// The first read after launch can be `.awaitingChallenge(step)`: a sign-in this session started before the
    /// app was closed, saved on the device, which the app may resume (present the step, then
    /// `confirmSignIn(challengeResponse:options:)`) or abandon (call `signIn` again). A resumed challenge whose
    /// Cognito session has since expired fails that answer with `AuthClientError.challengeExpired`.
    func currentSessionState() async -> AuthSessionState {
        let core = core
        return await core.sessionState()
    }

    /// Each new state of this session, after every transition. Not a change object, and no replay: the
    /// first element is the next change, so read `currentSessionState()` for where the session stands.
    ///
    /// A subscription does not keep the session alive. When the last handle and the last provider for
    /// the session go away, the stream finishes and a `for await` loop over it exits.
    func listenToSessionStateChanges() -> AsyncStream<AuthSessionState> {
        core.states.events()
    }

    /// The same four events the Hub sends today — signed in, signed out, session expired, user deleted —
    /// for this session only. No replay, and one order for every subscriber.
    ///
    /// Events come only from this session's own operations, never from observing storage, so a sign-in
    /// by another process produces no event here.
    ///
    /// A subscription does not keep the session alive. When the last handle and the last provider for
    /// the session go away, the stream finishes and a `for await` loop over it exits.
    func listenToAuthEvents() -> AsyncStream<AuthEvent> {
        core.events.events()
    }
}
