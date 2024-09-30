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
    let excludeAWSServices: Bool
    let excludeRuntimeTests: Bool
    let basePackageContents: () throws -> String
    
    init(
        clientRuntimeVersion: Version,
        crtVersion: Version,
        services: [Service],
        excludeAWSServices: Bool,
        excludeRuntimeTests: Bool,
        basePackageContents: @escaping () throws -> String
    ) {
        self.clientRuntimeVersion = clientRuntimeVersion
        self.crtVersion = crtVersion
        self.services = services
        self.excludeAWSServices = excludeAWSServices
        self.basePackageContents = basePackageContents
        self.excludeRuntimeTests = excludeRuntimeTests
    }
    
    init(
        clientRuntimeVersion: Version,
        crtVersion: Version,
        services: [Service],
        excludeAWSServices: Bool,
        excludeRuntimeTests: Bool
    ) {
        self.init(clientRuntimeVersion: clientRuntimeVersion, crtVersion: crtVersion, services: services, excludeAWSServices: excludeAWSServices, excludeRuntimeTests: excludeRuntimeTests) {
            // Returns the contents of the base package manifest stored in the bundle at `Resources/Package.Base.swift`
            let basePackageName = "Package.Base"
            
            // Get the url for the base package manifest that is stored in the bundle
            guard let url = Bundle.module.url(forResource: basePackageName, withExtension: "swift") else {
                throw Error("Could not find \(basePackageName).swift in bundle")
            }
            
            // Load the contents of the base package manifest
            let fileContents = try FileManager.default.loadContents(atPath: url.path)
            
            // Convert the base package manifest data to a string
            guard let fileText = String(data: fileContents, encoding: .utf8) else {
                throw Error("Failed to create string from contents of file \(basePackageName).swift")
            }
            
            return fileText
        }
    }
    
    // MARK: - Build
    
    /// Builds the contents of the package manifest file.
    func build() throws-> String {
        let contents = try [
            basePackageContents(),
            "",
            buildGeneratedContent()
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
            buildResolvedServices(),
            "\n"
        ]
        return contents.joined(separator: .newline)
    }
    
    /// Returns a pragma mark comment to provide separation between the non-generated (base) and generated content
    ///
    /// - Returns: A pragma mark comment to provide separation between the non-generated (base) and generated content
    private func buildPragmaMark() -> String {
        "// MARK: - Generated"
    }
    
    
    /// Builds the dependencies versions
    private func buildDependencies() -> String {
        """
        addDependencies(
            clientRuntimeVersion: \(clientRuntimeVersion.description.wrappedInQuotes()),
            crtVersion: \(crtVersion.description.wrappedInQuotes())
        )
        """
    }

    private func buildRuntimeTests() -> String {
        return [
            "// Uncomment this line to exclude runtime unit tests",
            (excludeRuntimeTests ? "" : "// ") + "excludeRuntimeUnitTests()"
        ].joined(separator: .newline)
    }

    /// Builds the list of services to include.
    /// This generates an array of strings, where the each item is a name of a service
    /// and calls the `addServiceTarget` for each item.
    private func buildServiceTargets() -> String {
        var lines: [String] = []
        lines += ["let serviceTargets: [String] = ["]
        lines += services.map { "    \($0.name.wrappedInQuotes())," }
        lines += ["]"]
        lines += [""]
        lines += ["// Uncomment this line to enable all services"]
        lines += ["\(excludeAWSServices ? "// " : "")addAllServices()"]

        return lines.joined(separator: .newline)
    }

    private func buildResolvedServices() -> String {
        "addResolvedTargets()"
    }
}
