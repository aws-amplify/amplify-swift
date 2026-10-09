//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The window a WebAuthn sheet attaches to, carried to the ceremony.
///
/// A **weak** reference, so a request never keeps a closed window alive: if the window has gone by the
/// time a ceremony starts, `anchor` is `nil`, and `WebAuthnCredentialOperations.associate` throws
/// `.validation("presentationAnchor", …)` without presenting. Boxed and unboxed on the main actor only,
/// which is what makes the `@unchecked Sendable` sound. Two boxes are equal when they are the same box.
///
/// A caller that must keep the window alive for the whole ceremony (the plugin, whose anchor is strong)
/// keeps its own strong reference beside the box.
package final class EnginePresentationAnchorBox: @unchecked Sendable {

    private weak var object: AnyObject?

    private init() {}

    /// A box holding no window: what a box is once its window has gone. For tests, which cannot close a window
    /// deterministically.
    package static func empty() -> EnginePresentationAnchorBox {
        EnginePresentationAnchorBox()
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    @MainActor
    package init(_ anchor: EnginePresentationAnchor) {
        self.object = anchor
    }

    /// The window, if it still exists.
    @MainActor
    package var anchor: EnginePresentationAnchor? {
        object as? EnginePresentationAnchor
    }
    #endif
}

extension EnginePresentationAnchorBox: Equatable {
    package static func == (lhs: EnginePresentationAnchorBox, rhs: EnginePresentationAnchorBox) -> Bool {
        lhs === rhs
    }
}
