//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ArgumentParser

public struct Version: Equatable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    private var versionString: String { "\(major).\(minor).\(patch)" }

    init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public init(_ value: String) throws {
        let components = value.split(separator: ".")
        guard components.count == 3 else {
            throw Error("Version does not have three components")
        }
        guard let major = Int(components[0]), let minor = Int(components[1]), let patch = Int(components[2]) else {
            throw Error("Version components are not all Int")
        }
        self.init(major, minor, patch)
    }
}

extension Version: CustomStringConvertible {
    public var description: String { versionString }
}

// MARK: - Codable

extension Version: Codable {

    public init(from decoder: Decoder) throws {
        try self.init(try String(from: decoder))
    }

    public func encode(to encoder: any Encoder) throws {
        try versionString.encode(to: encoder)
    }
}

// MARK: - Loading from File

public extension Version {
    /// Returns a version loaded from the provided file.
    /// The file's contents must only contain the version and nothing else.
    /// This is used to load a Version from a `Package.version` file.
    ///
    /// - Parameter filePath: The path to file containing the version
    /// - Returns: A version loaded from the provided file.
    static func fromFile(_ filePath: String) throws -> Version {
        let fileContents = try FileManager.default.loadContents(atPath: filePath)
        
        guard let versionString = String(data: fileContents, encoding: .utf8) else {
            throw Error("Failed to convert data to string for file at path: \(filePath)")
        }
        
        let normalizedVersionString = versionString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return try Version(normalizedVersionString)
    }
}

// MARK: - Incrementing versions

public extension Version {
    /// Returns a new version by incrementing the major version of the receiver
    ///
    /// - Returns: A new version by incrementing the major version of the receiver
    func incrementingMajor() -> Self {
       Version(
            self.major + 1,
            0,
            0
        )
    }
    
    /// Returns a new version by incrementing the minor version of the receiver
    ///
    /// - Returns: A new version by incrementing the minor version of the receiver
    func incrementingMinor() -> Self {
        Version(
            self.major,
            self.minor + 1,
            0
        )
    }
    
    /// Returns a new version by incrementing the patch version of the receiver
    ///
    /// - Returns: A new version by incrementing the patch version of the receiver
    func incrementingPatch() -> Self {
        Version(
            self.major,
            self.minor,
            self.patch + 1
        )
    }
}

// MARK: - ExpressibleByArgument

extension Version: ExpressibleByArgument {

    public init?(argument: String) {
        try? self.init(argument)
    }
}
