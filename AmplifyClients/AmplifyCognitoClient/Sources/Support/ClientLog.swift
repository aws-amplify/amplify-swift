//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation

/// The client's own log categories: every line the client logs outside the engine is logged under
/// `AmplifyCognitoClient.<area>`, so an app's sink can tell the client's lines from the Auth plugin's, and
/// from any other library's.
///
/// The engine's lines use the same prefix through `ClientEngineLogger`'s scopes (for example
/// `AmplifyCognitoClient.InitiateAuthSRP`). **No session ID** appears in a category: a session ID can be derived
/// from a user identifier, such as a username or `sub`.
enum ClientLog {

    /// The session record store: listing, copy-forward and the interrupted sign-in's record.
    static let sessionRecordStore = "SessionRecordStore"

    /// The sign-out of a session.
    static let sessionSignOut = "SessionSignOut"

    /// The keychain item stores the client builds over the real keychain.
    static let keychainItemStore = "KeychainItemStore"

    /// The hosted UI's sign-in: the warning that `.distinctFromOtherSessions` could not check the other sessions
    /// again once the browser returned (`SessionCore+WebUI.swift`).
    static let hostedUI = "HostedUI"

    /// The default session's shared saved login: the warning that it holds another principal
    /// (`SessionCore+SharedRecordWarning.swift`), which is temporary and goes with the plugin bridge, and the warning
    /// that a login deleted by a configuration change could not be revoked (`SessionCore+PluginConfiguration.swift`).
    /// The category stays.
    static let defaultSession = "DefaultSession"

    /// The logger for `area`, named `AmplifyCognitoClient.<area>`.
    static func logger(_ area: String) -> any AmplifyFoundation.Logger {
        ClientEngineLogger(name: category(area))
    }

    /// The category of `area`'s lines: `AmplifyCognitoClient.<area>`.
    static func category(_ area: String) -> String {
        "\(ClientEngineLogger.category).\(area)"
    }
}
