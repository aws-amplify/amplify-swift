//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation

/// Why a call that needs the system sheet was refused, which decides the wording of `browserBusy`.
///
/// The sheet may be a hosted-UI sign-in, a hosted-UI sign-out page or a passkey sheet, so the texts name
/// none of them.
enum BrowserBusyReason: Equatable {

    /// Another session holds the sheet.
    case heldByAnotherSession

    /// The asking session already holds the sheet.
    case alreadyInFlight

    /// The asking session is already queued for the sheet.
    case alreadyQueued

    /// The asking session's previous flow was cancelled and its sheet is still closing.
    case stillClosing

    /// The asking session waited with `whenBrowserBusy: .wait(timeout:)`, and the timeout expired first.
    case timedOut
}

extension AuthClientError {

    /// `browserBusy`, naming `holder` so an app can tell the user which sign-in to finish first.
    static func browserBusy(
        heldBy holder: SessionID,
        requestedBy requester: SessionID,
        reason: BrowserBusyReason
    ) -> AuthClientError {
        switch reason {
        case .alreadyInFlight:
            return .browserBusy(
                holder: holder,
                "Session \"\(holder)\" already has a system sheet in progress.",
                "Wait for it to finish, or cancel it, before starting another for the same session."
            )
        case .alreadyQueued:
            return .browserBusy(
                holder: holder,
                "Session \"\(requester)\" is already waiting for the system sheet, which session \"\(holder)\" holds.",
                "Wait for the earlier call to finish, or cancel it. One session queues for the sheet at most once."
            )
        case .stillClosing:
            return .browserBusy(
                holder: holder,
                "Session \"\(holder)\"'s previous system sheet is still closing.",
                "Retry once it has closed, or pass `whenBrowserBusy: .wait(timeout:)` to start as soon as it has."
            )
        case .heldByAnotherSession:
            return .browserBusy(
                holder: holder,
                "Session \"\(holder)\" is showing a system sheet, and only one can be shown at a time.",
                "Ask the user to finish with that session's sheet first, or cancel it. "
                    + "To queue behind it instead, pass `whenBrowserBusy: .wait(timeout:)`."
            )
        case .timedOut:
            return .browserBusy(
                holder: holder,
                "Session \"\(requester)\" waited for the system sheet until its timeout, and session \"\(holder)\" still holds it.",
                "Retry later, or wait longer with `whenBrowserBusy: .wait(timeout:)`. "
                    + "To free a sheet that has stopped responding, call `AmplifyCognitoClient.resetSystemSheet()`."
            )
        }
    }

    /// `browserBusy` with the reason inferred: the holder itself asking, or another session.
    static func browserBusy(heldBy holder: SessionID, requestedBy requester: SessionID) -> AuthClientError {
        browserBusy(
            heldBy: holder,
            requestedBy: requester,
            reason: holder == requester ? .alreadyInFlight : .heldByAnotherSession
        )
    }
}
#endif
