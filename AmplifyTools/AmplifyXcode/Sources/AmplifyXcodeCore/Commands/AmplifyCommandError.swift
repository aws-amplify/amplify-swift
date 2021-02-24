//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AmplifyCommandError: Error {
    public enum AmplifyCommandErrorType {
        case unknown
        case fileNotFound
        case folderNotFound
        case xcodeProject
    }

    let type: AmplifyCommandErrorType
    let errorDescription: String?
    let recoverySuggestion: String?

    var underlyingErrors: [Error]?

    init(_ type: AmplifyCommandErrorType, errorDescription: String?, recoverySuggestion: String?, error: Error? = nil) {
        self.type = type
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion

        if let error = error {
            self.underlyingErrors = [error]
        }
    }

    init(_ type: AmplifyCommandErrorType, error: Error?) {
        self.init(type, errorDescription: nil, recoverySuggestion: nil, error: error)
    }

    init(errors: [AmplifyCommandError]) {
        self.init(.unknown, errorDescription: nil, recoverySuggestion: nil, error: nil)
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

public extension AmplifyCommandError {
    var debugDescription: String {
        var components = ["\(type): \(errorDescription ?? "")"]
        if let recoveryMsg = recoverySuggestion {
            components.append("-- Recovery suggestion: \(recoveryMsg)")
        }

        guard let underlyingErrors = self.underlyingErrors else {
            return components.joined(separator: "\n")
        }

        if underlyingErrors.count == 1, let error = underlyingErrors.first as? AmplifyCommandError {
            return error.debugDescription
        }

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
