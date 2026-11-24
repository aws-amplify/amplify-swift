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
/// which is what makes the `@unchecked Sendable` sound. Two boxes are equal when they are the same box;
/// `sameWindow(_:_:)` compares the windows they were made from.
///
/// A caller that must keep the window alive for the whole ceremony (the plugin, whose anchor is strong)
/// keeps its own strong reference beside the box.
package final class EnginePresentationAnchorBox: @unchecked Sendable {

    private weak var object: AnyObject?

    /// The window's identity, recorded when it was boxed, for `sameWindow(_:_:)`. `nil` for `empty()`.
    private let identity: ObjectIdentifier?

    private init() {
        self.identity = nil
    }

    /// A box holding no window: what a box is once its window has gone. For tests, which cannot close a window
    /// deterministically.
    package static func empty() -> EnginePresentationAnchorBox {
        EnginePresentationAnchorBox()
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    @MainActor
    package init(_ anchor: EnginePresentationAnchor) {
        self.object = anchor
        self.identity = ObjectIdentifier(anchor)
    }

    /// The window, if it still exists.
    @MainActor
    package var anchor: EnginePresentationAnchor? {
        object as? EnginePresentationAnchor
    }
    #endif

    /// Whether two boxes were made from the same window. No box on both sides is the same; a box and no box
    /// never are, even once the box's window has gone.
    ///
    /// It compares the identities recorded when the windows were boxed and never reads the window, so it is
    /// safe off the main actor and takes no reference to a window that may be closing. The limit: an identity is
    /// unique only while its window lives, so a box whose window has gone can match the box of a later window
    /// that reuses its address.
    package static func sameWindow(_ lhs: EnginePresentationAnchorBox?, _ rhs: EnginePresentationAnchorBox?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (let lhs?, let rhs?):
            return lhs.identity == rhs.identity
        default:
            return false
        }
    }
}

extension EnginePresentationAnchorBox: Equatable {
    package static func == (lhs: EnginePresentationAnchorBox, rhs: EnginePresentationAnchorBox) -> Bool {
        lhs === rhs
    }
}
