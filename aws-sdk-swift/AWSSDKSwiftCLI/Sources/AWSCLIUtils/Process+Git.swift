//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import struct ArgumentParser.ExitCode

public extension Process {
    /// A struct to create processes for executing git commands.
    struct Git {
        /// Returns a process for executing git commands.
        private func gitProcess(_ args: [String]) -> Process {
            Process(["git"] + args)
        }
        
        /// Returns a process for executing `git status`
        public func status() -> Process {
            gitProcess(["status"])
        }
        
        /// Returns a process for executing `git diff <a>..<b> --quiet`
        /// This is used for determining if `<a>` is different from `<b>` and therefore
        public func diff(_ a: String, _ b: String) -> Process {
            gitProcess(["diff", "\(a)..\(b)", "--quiet"])
        }
        
        /// Returns a process for executing `git add <args>`
        /// This is used for staging specific files.
        public func add(_ files: [String]) -> Process {
            gitProcess(["add"] + files)
        }
        
        /// Returns a process for executing `git commit -m <message>`
        /// This is used for committing changes with the provided message
        public func commit(_ message: String) -> Process {
            gitProcess(["commit", "-m", message])
        }
        
        /// Returns a process for executing `git tag -a <version> -m <message>`
        /// This is used for creating a tag with the provided version and message.
        public func tag(_ version: Version, _ message: String) -> Process {
            gitProcess(["tag", "-a", "\(version)", "-m", message])
        }
        
        /// Returns a process for executing `git update-index --refresh`
        /// This is used to clear the index of any files that were changed but their contents don't include any changes when compared to the existing file.
        /// For example when generating code, such as a service client, this would clear the index if the generated code is exactly the same as the existing code.
        func updateIndex() -> Process {
            gitProcess(["update-index", "--refresh"])
        }
        
        /// Returns a process for executing `git diff index --quiet HEAD --`
        /// This is used for determining if the local working copy has changes
        func diffIndex() -> Process {
            gitProcess(["diff-index", "--quiet", "HEAD", "--"])
        }
        
        /// Returns a process for executing `git log <a>..<b> --pretty=format:<format>`
        /// This is used returning the list of commits between two tags.
        func log(_ a: String, _ b: String, format: String) -> Process {
            gitProcess(["log", "\(a)...\(b)", "--pretty=format:\(format)"])
        }
    }
    
    static var git: Git { Git() }
}

public extension Process.Git {
    /// Returns true if the provided commits/branches/trees are different, otherwise returns false
    func diffHasChanges(_ a: String, _ b: String) throws -> Bool {
        let task = diff(a, b)
        do {
            try _run(task)
        } catch let exitCode as ExitCode where exitCode.rawValue == 1 {
            return true
        }
        return false
    }
    
    /// Returns true if the local working copy has unstaged or uncommitted changes, otherwise returns false.
    func hasLocalChanges() throws -> Bool {
        let updateIndexTask = updateIndex()
        try? _run(updateIndexTask)
        
        do {
            let diffIndexTask = diffIndex()
            try _run(diffIndexTask)
        } catch let exitCode as ExitCode where exitCode.rawValue == 1 {
            return true
        }
        return false
    }
    
    func listOfCommitsBetween(_ a: String, _ b: String) throws -> [String] {
        let log = log(a, b, format: "%s")
        let result = try _runReturningStdOut(log)
        return result?.components(separatedBy: .newlines) ?? []
    }
}
