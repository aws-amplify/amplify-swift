//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCLIUtils

/// Builds the contents of the package manifest file.
struct PackageManifestBuilder {
    struct Service {
        let name: String
    }

    let clientRuntimeVersion: Version
    let crtVersion: Version
    let services: [Service]
    let excludeRuntimeTests: Bool
    let prefixContents: () throws -> String
    let basePackageContents: () throws -> String
    
    init(
        clientRuntimeVersion: Version,
        crtVersion: Version,
        services: [Service],
        excludeRuntimeTests: Bool,
        prefixContents: @escaping () throws -> String,
        basePackageContents: @escaping () throws -> String
    ) {
        self.clientRuntimeVersion = clientRuntimeVersion
        self.crtVersion = crtVersion
        self.services = services
        self.excludeRuntimeTests = excludeRuntimeTests
        self.prefixContents = prefixContents
        self.basePackageContents = basePackageContents
    }
    
    init(
        clientRuntimeVersion: Version,
        crtVersion: Version,
        services: [Service],
        excludeRuntimeTests: Bool
    ) {
        self.init(
            clientRuntimeVersion: clientRuntimeVersion,
            crtVersion: crtVersion,
            services: services,
            excludeRuntimeTests: excludeRuntimeTests,
            prefixContents: Self.contentReader(filename: "Package.Prefix"),
            basePackageContents: Self.contentReader(filename: "Package.Base")
        )
    }

    static func contentReader(filename: String) -> () throws -> String {
        return {
            // Get the url for the file that is stored in the bundle
            guard let url = Bundle.module.url(forResource: filename, withExtension: "txt") else {
                throw Error("Could not find \(filename).txt in bundle")
            }

            // Load the contents of the base package manifest
            let fileContents = try FileManager.default.loadContents(atPath: url.path)

            // Convert the base package manifest data to a string
            guard let fileText = String(data: fileContents, encoding: .utf8) else {
                throw Error("Failed to create string from contents of file \(filename).txt")
            }

            return fileText
        }
    }

    // MARK: - Build
    
    /// Builds the contents of the package manifest file.
    func build() throws-> String {
        let contents = try [
            prefixContents(),
            buildGeneratedContent(),
            basePackageContents(),
        ]
        return contents.joined(separator: .newline)
    }
    
    /// Builds all the generated package manifest content
    private func buildGeneratedContent() -> String {
        let contents = [
            // Start with a pragma mark to provide a clear separation between the non-generated (base) and generated content
            buildPragmaMark(),
            "",
            // Add the generated content that defines the dependencies' versions
            buildDependencies(),
            "",
            // Remove the runtime tests if needed
            buildRuntimeTests(),
            "",
            // Add the generated content that defines the list of services to include
            buildServiceTargets(),
            "",
        ]
        return contents.joined(separator: .newline)
    }
    
    /// Returns a pragma mark comment to provide separation between the non-generated (base) and generated content
    ///
    /// - Returns: A pragma mark comment to provide separation between the non-generated (base) and generated content
    private func buildPragmaMark() -> String {
        "// MARK: - Dynamic Content"
    }
    
    
    /// Builds the dependencies versions
    private func buildDependencies() -> String {
        """
        let clientRuntimeVersion: Version = \(clientRuntimeVersion.description.wrappedInQuotes())
        let crtVersion: Version = \(crtVersion.description.wrappedInQuotes())
        """
    }

    private func buildRuntimeTests() -> String {
        "let excludeRuntimeUnitTests = \(excludeRuntimeTests)"
    }

    /// Builds the list of services to include.
    /// This generates an array of strings, where the each item is a name of a service
    /// and calls the `addServiceTarget` for each item.
    private func buildServiceTargets() -> String {
        var lines: [String] = []
        lines += ["let serviceTargets: [String] = ["]
        lines += services.map { "    \($0.name.wrappedInQuotes())," }
        lines += ["]"]
        return lines.joined(separator: .newline)
    }
}
