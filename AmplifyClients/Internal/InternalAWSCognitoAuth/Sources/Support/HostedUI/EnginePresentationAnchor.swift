//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// The presentation anchor type as the engine names it.
//
// It is the same type as `Amplify.AuthUIPresentationAnchor` on every platform, so values cross the
// plugin boundary as they are. It has its own name because plugin files import both `Amplify` and
// this module, and two same-named typealiases would rely on untested lookup rules.

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices

package typealias EnginePresentationAnchor = ASPresentationAnchor
#elseif os(watchOS) || os(tvOS)
package typealias EnginePresentationAnchor = AuthUIPresentationAnchorPlaceholder
#endif
