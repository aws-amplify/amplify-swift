//
// Copyright Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AmplifyCommandError: Error {
    enum AmplifyCommandErrorType {
        case unknown
        case fileNotFound
        case folderNotFound
        case xcodeProject
    }

    let type: AmplifyCommandErrorType
    let recoverySuggestion: String?

    var underlyingErrors: [Error]?

    init(_ type: AmplifyCommandErrorType, error: Error?, recoverySuggestion: String?) {
        self.type = type
        self.recoverySuggestion = recoverySuggestion

        if let error = error {
            self.underlyingErrors = [error]
        }
    }

    init(_ type: AmplifyCommandErrorType, error: Error?) {
        self.init(type, error: error, recoverySuggestion: nil)
    }

    init(errors: [AmplifyCommandError]) {
        self.init(.unknown, error: nil, recoverySuggestion: nil)
        self.underlyingErrors = errors
    }

    init(from tasks: [AmplifyCommandTaskResult]) {
        let errors: [AmplifyCommandError] = tasks.compactMap { result in
            switch result {
            case .failure(let error):
                return error
            case .success:
                return nil
            }
        }
        self.init(errors: errors)
    }

}

extension AmplifyCommandError {
    var debugDescription: String {
        var components = ["\(type): "]

        if let recoveryMsg = recoverySuggestion {
            components.append("-- Recovery suggestion: \(recoveryMsg)")
        }

        let underlyingErrors = self.underlyingErrors ?? []
        for err in underlyingErrors {
            if let underlyingAmplifyError = err as? AmplifyCommandError {
                components.append("-- Caused by: \(underlyingAmplifyError.debugDescription)")
            } else {
                components.append("-- Caused by: \(err)")
            }
        }
        return components.joined(separator: "\n")
    }
}
