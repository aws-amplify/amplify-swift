//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AmplifyCommandEnvironmentFileManager {
    var basePathURL: URL { get }
    var basePath: String { get }
    var currentFolder: String { get }

    init(basePath: String)

    func path(for file: String ) -> String
    func path(for components: [String]) -> String
    func create(directory: String) throws -> String
    func create(file: String, content: String)
    func content(of directory: String) throws -> [String]
    func directoryExists(at path: String) -> Bool
}

protocol AmplifyCommandEnvironmentXcode {
    func xcode(project path: String, add files: [XcodeProjectFile], toGroup group: String) throws
}

typealias AmplifyCommandEnvironment = AmplifyCommandEnvironmentFileManager & AmplifyCommandEnvironmentXcode
