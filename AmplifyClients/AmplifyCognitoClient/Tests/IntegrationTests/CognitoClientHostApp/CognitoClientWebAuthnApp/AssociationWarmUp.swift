//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AuthenticationServices
import Foundation
import MachO

/// Waits until the simulator has verified this app's association with its relying party.
///
/// On a freshly booted or erased simulator, the first passkey requests fail with `ASAuthorizationError` code
/// 1004 ("Unable to verify webcredentials association") while the device fetches the relying party's
/// apple-app-site-association (again after every install), and a sheet shown in that window can stall. The
/// UI tests run this after every launch, before the flow, so the flow's first ceremony meets a verified association.
///
/// Each probe is an assertion for the relying party with a random challenge, performed with
/// `.preferImmediatelyAvailableCredentials`: with no passkey for the relying party on the device it answers at
/// once and shows nothing; with one (a passkey left by an earlier run) the sheet may appear, and the probe
/// closes it after a moment. Either answer other than 1004 means the association is verified.
@MainActor
final class AssociationWarmUp: NSObject {

    /// How long the warm-up tries, and how long a probe waits for its answer before closing its sheet.
    static let limit: TimeInterval = 120
    private static let probeTimeout: TimeInterval = 3
    private static let associationErrorCode = 1_004

    private let anchor: ASPresentationAnchor
    private var continuation: CheckedContinuation<Error?, Never>?
    private var controller: ASAuthorizationController?

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    /// Probes until the association is verified, or `limit` has passed.
    ///
    /// - Returns: how many probes it took.
    func run() async throws -> Int {
        let relyingParty = try Self.relyingParty()
        let deadline = Date().addingTimeInterval(Self.limit)
        var probes = 0
        while true {
            probes += 1
            let error = await probe(relyingParty)
            // A probe the controller never answered tells nothing: it counts as unverified, like 1004.
            let unverified = error is ProbeUnanswered
                || (error as? ASAuthorizationError)?.code.rawValue == Self.associationErrorCode
            guard unverified else {
                return probes
            }
            guard Date() < deadline else {
                throw HarnessAppError("The relying party's association was still unverified (1004, or no answer) after \(probes) probes")
            }
            try await Task.sleep(nanoseconds: 3_000_000_000)
        }
    }

    /// One probe. `nil` when it succeeded, else its error.
    private func probe(_ relyingParty: String) async -> Error? {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingParty)
        let request = provider.createCredentialAssertionRequest(challenge: Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) }))
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller
        let closer = Task { @MainActor [weak self, weak controller] in
            // A sheet is up (a passkey exists): the association is verified; close it.
            guard (try? await Task.sleep(nanoseconds: UInt64(Self.probeTimeout * 1_000_000_000))) != nil else {
                return
            }
            controller?.cancel()
            // A cancel the controller never answers must not leave the probe waiting forever.
            guard (try? await Task.sleep(nanoseconds: UInt64(Self.probeTimeout * 1_000_000_000))) != nil else {
                return
            }
            self?.finish(ProbeUnanswered())
        }
        let error = await withCheckedContinuation { continuation in
            self.continuation = continuation
            controller.performRequests(options: .preferImmediatelyAvailableCredentials)
        }
        closer.cancel()
        self.controller = nil
        return error
    }

    private func finish(_ error: Error?) {
        continuation?.resume(returning: error)
        continuation = nil
    }

    /// The `webcredentials:` domain of this app's associated domains, from the entitlements the simulator build
    /// embeds in the executable (`__TEXT,__entitlements`), so the domain is written down only in the two
    /// entitlements files (this app's and the plugin's `AuthWebAuthnApp.entitlements`, which `infra/parity.py`
    /// keeps equal).
    static func relyingParty() throws -> String {
        var size: UInt = 0
        guard let header = mainExecutableHeader(),
              let bytes = getsectiondata(header, "__TEXT", "__entitlements", &size),
              size > 0 else {
            throw HarnessAppError("The app's embedded entitlements were not found (simulator builds only)")
        }
        let data = Data(bytes: bytes, count: Int(size))
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        let domains = plist?["com.apple.developer.associated-domains"] as? [String] ?? []
        guard let entry = domains.first(where: { $0.hasPrefix("webcredentials:") }) else {
            throw HarnessAppError("The app's entitlements name no webcredentials domain")
        }
        let domain = entry.dropFirst("webcredentials:".count)
        return String(domain.split(separator: "?").first ?? domain)
    }

    /// The Mach-O header of the app's own executable, found by its path: image 0 is not always it under the
    /// simulator.
    private static func mainExecutableHeader() -> UnsafePointer<mach_header_64>? {
        guard let executable = Bundle.main.executableURL?.resolvingSymlinksInPath().path else {
            return nil
        }
        for index in 0 ..< _dyld_image_count() {
            guard let name = _dyld_get_image_name(index),
                  URL(fileURLWithPath: String(cString: name)).resolvingSymlinksInPath().path == executable,
                  let header = _dyld_get_image_header(index) else {
                continue
            }
            return UnsafeRawPointer(header).assumingMemoryBound(to: mach_header_64.self)
        }
        return nil
    }
}

/// A probe that finished by itself, because the controller never answered its cancel.
private struct ProbeUnanswered: Error {}

extension AssociationWarmUp: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        MainActor.assumeIsolated { finish(nil) }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        MainActor.assumeIsolated { finish(error) }
    }
}

extension AssociationWarmUp: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated { anchor }
    }
}
