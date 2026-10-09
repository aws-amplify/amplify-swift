//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Deleting the user of a session that holds none.
extension DeleteUserTests {

    /// Deleting the user of a signed-out session throws `.notSignedIn` and sends nothing
    /// (DU-2; the plugin's `testDeleteUserFromUnauthState`, whose `AuthError.signedOut` is the client's
    /// `.notSignedIn`).
    ///
    /// - Given: a client on a fresh session that never signed in, the recorder installed
    /// - When:
    ///    - `deleteUser()`
    /// - Then:
    ///    - it throws `.notSignedIn`, the recorder saw no request, and the state is still `.signedOut`
    ///
    func testDeleteUserWhenSignedOutThrowsNotSignedIn() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("delete-signed-out", configureUserPoolClient: recorder.configureUserPoolClient)

        let error = await Expect.authClientError("deleting the user of a signed-out session") {
            try await client.deleteUser()
        }

        XCTAssertEqual(error?.kind, .notSignedIn)
        XCTAssertEqual(recorder.operations, [], "nothing is sent for a session with no user")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedOut)
    }
}
