//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Commonly used cross-category error messages.
public struct AmplifyErrorMessages {

    /// <#Description#>
    /// - Parameters:
    ///   - file: <#file description#>
    ///   - function: <#function description#>
    ///   - line: <#line description#>
    /// - Returns: <#description#>
    public static func reportBugToAWS(file: StaticString = #file,
                                      function: StaticString = #function,
                                      line: UInt = #line) -> String {
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

    /// <#Description#>
    /// - Parameters:
    ///   - file: <#file description#>
    ///   - function: <#function description#>
    ///   - line: <#line description#>
    /// - Returns: <#description#>
    public static func shouldNotHappenReportBugToAWS(file: StaticString = #file,
                                                     function: StaticString = #function,
                                                     line: UInt = #line) -> String {
        "This should not happen. \(reportBugToAWS(file: file, function: function, line: line))"
    }

}
