//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices

/// The window a system sheet attaches to: the hosted UI's browser, and (with WebAuthn) the passkey sheet.
/// `ASPresentationAnchor`, which is `UIWindow` or `NSWindow`.
///
/// Required wherever a sheet may appear. The client never hunts for a window of its own, so a sheet is
/// always shown over the window the app chose, and an app with several scenes gets no surprises.
@_spi(AmplifyExperimental)
public typealias AuthClientPresentationAnchor = ASPresentationAnchor
#endif
