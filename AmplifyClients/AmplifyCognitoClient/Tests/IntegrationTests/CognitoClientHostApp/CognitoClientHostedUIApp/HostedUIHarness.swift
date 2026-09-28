//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import SwiftUI
import UIKit

@MainActor
enum HostedUIHarness {

    /// The hosted-UI app client's outputs file (P-7: the `default` pool, its `…-hostedui` client and the
    /// `oauth` block), copied into the app bundle at build time from `~/.amplify-cognito-client-integ` (the
    /// "Copy sandbox configuration" phase).
    static let outputsResource = "hosted-ui-amplify_outputs"

    /// The client on the default session, as an app with one user would use it.
    static func makeClient() -> Result<AmplifyCognitoClient, HarnessAppError> {
        guard Bundle.main.url(forResource: outputsResource, withExtension: "json") != nil else {
            return .failure(HarnessAppError(
                "\(outputsResource).json is not in the app bundle. Run infra/provision.sh, then rebuild."
            ))
        }
        do {
            return try .success(AmplifyCognitoClient(from: outputsResource, bundle: .main))
        } catch {
            return .failure(HarnessAppError("Could not configure the client: \(error)"))
        }
    }

    /// HU-2's anchor: the key window of the scene in the foreground, which the app looks up itself. It is
    /// the lookup the plugin's `signInWithWebUI(presentationAnchor: nil)` does internally; the client takes
    /// a non-optional anchor, so an app with no view at hand does the same.
    static func foregroundKeyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let active = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        return active?.keyWindow ?? active?.windows.first
    }
}

/// The window a SwiftUI view is in: HU-1's anchor, the view's own window, as the plugin's app passes its
/// scene's window.
@MainActor
final class WindowHolder {
    weak var window: UIWindow?
}

/// Reports the window it is placed in to a `WindowHolder`. Put it in a view's background.
struct WindowReader: UIViewRepresentable {
    let holder: WindowHolder

    func makeUIView(context: Context) -> WindowReportingView {
        let view = WindowReportingView()
        view.holder = holder
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: WindowReportingView, context: Context) {
        uiView.holder = holder
        holder.window = uiView.window
    }
}

final class WindowReportingView: UIView {
    var holder: WindowHolder?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        holder?.window = window
    }
}

struct HarnessAppError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
