//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Verbatim copies of the `AmplifyErrorMessages` members the engine uses
/// (`Amplify/Core/Support/AmplifyErrorMessages.swift`), so engine errors keep their text without
/// depending on `Amplify`.
///
/// Used by `DeleteUser`, `FetchSessionError`, `AuthorizationError`, `EngineAuthError` and the
/// credential-store error (`KeychainStoreError.swift:78,88,91`). `EngineErrorMessagesTests` checks every member against
/// Amplify's. Do not edit one side only.
package enum EngineErrorMessages {

    /// Copy of `AmplifyErrorMessages.reportBugToAWS(file:function:line:)`.
    package static func reportBugToAWS(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> String {
        """
        There is a possibility that there is a bug if this error persists. Please take a look at \
        https://github.com/aws-amplify/amplify-ios/issues to see if there are any existing issues that \
        match your scenario, and file an issue with the details of the bug if there isn't. Issue encountered \
        at:
        file: \(file)
        function: \(function)
        line: \(line)
        """
    }

    /// Copy of `AmplifyErrorMessages.shouldNotHappenReportBugToAWS(file:function:line:)`.
    package static func shouldNotHappenReportBugToAWS(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> String {
        "This should not happen. \(reportBugToAWS(file: file, function: function, line: line))"
    }

    /// Copy of `AmplifyErrorMessages.shouldNotHappenReportBugToAWSWithoutLineInfo()`, the recovery
    /// suggestion of `EngineAuthError.unknown`.
    package static func shouldNotHappenReportBugToAWSWithoutLineInfo() -> String {
        """
        This should not happen. There is a possibility that there is a bug if this error persists. \
        Please take a look at https://github.com/aws-amplify/amplify-swift/issues to see if there \
        are any existing issues that match your scenario, and file an issue with the details of \
        the bug if there isn't.
        """
    }
}
