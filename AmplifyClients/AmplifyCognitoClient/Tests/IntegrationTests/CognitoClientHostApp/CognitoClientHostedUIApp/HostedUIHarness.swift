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

    /// The plugin's hosted-UI backend's outputs file, with its `oauth` block (on the sandbox, P-7: the
    /// `default` pool and its `…-hostedui-plugin` client, redirecting to `myapp://`), copied into the app
    /// bundle at build time from `$COGNITO_CLIENT_INTEG_DIR` (default `~/.aws-amplify/amplify-ios/testconfiguration`,
    /// the "Copy test configuration" phase). Where only the plugin's Gen1 file for the backend was copied (as
    /// on the plugin's CI), the client is given its Gen2 translation under this name (`PluginTestConfiguration`).
    static let outputsResource = "AWSCognitoAuthPluginHostedUIIntegrationTests-amplify_outputs"

    /// The client on the default session, as an app with one user would use it. `.default`'s saved login is the
    /// Auth plugin's own record, `amplify.<ns>.session`, with the client's sidecar beside it, in this
    /// app's own keychain group: an app moving from the plugin keeps its user signed in, and no other host app
    /// sees this one's login.
    static func makeClient() -> Result<AmplifyCognitoClient, HarnessAppError> {
        guard PluginTestConfiguration.isPresent(outputsResource, in: .main) else {
            return .failure(HarnessAppError(
                "\(PluginTestConfigurationError(missing: outputsResource).description) It is copied from $COGNITO_CLIENT_INTEG_DIR at build time."
            ))
        }
        do {
            return try .success(AmplifyCognitoClient(
                from: outputsResource,
                bundle: PluginTestConfiguration.outputsBundle(outputsResource, in: .main)
            ))
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

extension AuthClientSignOutResult {

    /// What a sign-out that signed the user out on this device left undone, by case names only, for the result
    /// line: "" for `.complete`, else the parts that failed, as `revokeTokenError: service`. Never an error's text or
    /// payload, which can hold a username, a service message or an identifier, and the UI tests print the line.
    var failedParts: String {
        guard case .partial(let revoke, let global, let hostedUI, let storage) = self else {
            return ""
        }
        let parts: [(String, AuthClientError?)] = [
            ("revokeTokenError", revoke),
            ("globalSignOutError", global),
            ("hostedUIError", hostedUI),
            ("storageError", storage)
        ]
        return parts.compactMap { name, error in error.map { "\(name): \($0.harnessCaseName)" } }.joined(separator: ", ")
    }
}

extension AuthClientError {

    /// The error's case name alone (`browserBusy`, `userCancelled`), never its text or payload.
    var harnessCaseName: String {
        Mirror(reflecting: self).children.first?.label ?? "unknown"
    }
}
