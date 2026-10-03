//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(watchOS) || os(tvOS)

import InternalAWSCognitoAuth

/// The placeholder class now lives in `InternalAWSCognitoAuth`
/// (`Support/HostedUI/AuthUIPresentationAnchorPlaceholder.swift`). This keeps the plugin's own
/// `internal` name, so plugin files that do not import the internal target still resolve
/// `AuthUIPresentationAnchor` on tvOS and watchOS. On iOS, macOS and visionOS the name comes from
/// `Amplify` (`ASPresentationAnchor`), as before.
typealias AuthUIPresentationAnchor = AuthUIPresentationAnchorPlaceholder

#endif
