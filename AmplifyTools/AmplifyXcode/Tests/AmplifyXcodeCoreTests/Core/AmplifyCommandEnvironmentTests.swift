//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyXcodeCore

class AmplifyCommandEnvironmentTests: XCTestCase {
    var environment: AmplifyCommandEnvironment?
    var fileManager = MockAmplifyFileManager()
    let basePath = "/Test/Env/"

    override func setUp() {
        environment = CommandEnvironment(basePath: basePath, fileManager: fileManager)
    }

    // MARK: - path(for:)
    func testPathWithFolder() throws {
        let subPath = "Project"
        let fullPath = environment?.path(for: subPath)
        XCTAssertEqual(fullPath, "\(basePath)\(subPath)")
    }

    func testPathWithDeeplyNestedSubpath() {
        let subPath = "Project/Folder/SubFolder/SubSubFolder"
        let fullPath = environment?.path(for: subPath)
        XCTAssertEqual(fullPath, "\(basePath)\(subPath)")
    }

    // MARK: - path(for components:)
    func testComponentsSubpath() {
        let pathComponents = ["Project", "Folder", "SubFolder", "SubSubFolder"]
        let fullPath = environment?.path(for: pathComponents)
        XCTAssertNotNil(fullPath)
    }

    // MARK: - glob
    func testGlob() {
        let pattern = "Project/*.swift"
        _ = environment?.glob(pattern: pattern)
        XCTAssertEqual(fileManager.globCalledTimes, 1)
    }

    // MARK: - createDirectory
    func testCreateDirectory() throws {
        let path = "Folder"
        let dirPath = try environment?.createDirectory(atPath: path)
        XCTAssertEqual(fileManager.createDirectoryCalledTimes, 1)
        XCTAssertEqual(dirPath, "\(basePath)\(path)")
        XCTAssertNotNil(dirPath)
    }

    func testCreateDirectoryThrowsIfFileManagerFails() throws {
        class ThrowingFileManager: MockAmplifyFileManager {
            override func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
                throw AmplifyCommandError(.unknown, error: nil)
            }
        }
        let environment = CommandEnvironment(basePath: basePath, fileManager: ThrowingFileManager())

        let path = "Folder"
        XCTAssertThrowsError(try environment.createDirectory(atPath: path))
    }

    // MARK: - createFile
    func testCreateFile() throws {
        let path = "file"
        let fileContent = ""
        let fullPath = try environment?.createFile(atPath: path, content: fileContent)
        XCTAssertEqual(fileManager.createFileCalledTimes, 1)
        XCTAssertEqual(fullPath, "\(basePath)\(path)")
        XCTAssertNotNil(fullPath)
    }

    func testCreateFileThrowsIfFileManagerFails() throws {
        class ThrowingFileManager: MockAmplifyFileManager {
            override func createFile(atPath: String, contents: Data?) -> Bool {
                return false
            }
        }
        let environment = CommandEnvironment(basePath: basePath, fileManager: ThrowingFileManager())
        let path = "file"
        let fileContent = ""
        XCTAssertThrowsError(try environment.createFile(atPath: path, content: fileContent))
    }

    // MARK: - contentsOfDirectory
    func testContentsOfDirectory() throws {
        let dirPath = "directory/subPath"
        _ = try environment?.contentsOfDirectory(atPath: dirPath)
        XCTAssertEqual(fileManager.directoryExistsCalledTimes, 1)
        XCTAssertEqual(fileManager.contentsOfDirectoryCalledTimes, 1)
    }

    func testContentsOfDirectoryThrowsIfDirectoryDoesNotExist() {
        class DirNotFoundFileManager: MockAmplifyFileManager {
            override func directoryExists(atPath: String) -> Bool {
                false
            }
        }
        let dirPath = "directory/subPath"
        let environment = CommandEnvironment(basePath: basePath, fileManager: DirNotFoundFileManager())
        XCTAssertThrowsError(try environment.contentsOfDirectory(atPath: dirPath))
    }

    func testContentsOfDirectoryThrowsIfFileManagerThrows() {
        class ThrowingFileManager: MockAmplifyFileManager {
            override func contentsOfDirectory(atPath: String) throws -> [String] {
                throw AmplifyCommandError(.unknown, error: nil)
            }
        }
        let dirPath = "directory/subPath"
        let environment = CommandEnvironment(basePath: basePath, fileManager: ThrowingFileManager())
        XCTAssertThrowsError(try environment.contentsOfDirectory(atPath: dirPath))
    }

    // MARK: - directoryExists
    func testDirectoryExists() {
        _ = environment?.directoryExists(atPath: "path")
        XCTAssertEqual(fileManager.directoryExistsCalledTimes, 1)
    }

    // MARK: - createXcodeFile
    func testCreateXcodeSourceFiles() {
        let files = ["File1.swift", "Folder/File2.swift"]
        for file in files {
            let xcodeFile = environment?.createXcodeFile(withPath: file, ofType: .source)
            XCTAssertEqual(xcodeFile, XcodeProjectFile(file, type: .source))
        }
    }

    func testCreateXcodeResourceFiles() {
        let files = ["View.xib", "Folder/File.json"]
        for file in files {
            let xcodeFile = environment?.createXcodeFile(withPath: file, ofType: .resource)
            XCTAssertEqual(xcodeFile, XcodeProjectFile(file, type: .resource))
        }
    }

    // MARK: - addFilesToXcodeProject
    func testAddFilesToXcodeThrowsIfProjectDoesNotExist() {
        class DirNotFoundFileManager: MockAmplifyFileManager {
            override func contentsOfDirectory(atPath: String) throws -> [String] {
                ["not-an-xcode-project-file.txt"]
            }
        }
        let environment = CommandEnvironment(basePath: basePath, fileManager: DirNotFoundFileManager())
        let file = environment.createXcodeFile(withPath: "File.swift", ofType: .source)
        XCTAssertThrowsError(try environment.addFilesToXcodeProject(projectPath: "project",
                                                                    files: [file],
                                                                    toGroup: "group",
                                                                    inTarget: .primary))
    }
}
