//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Helper class to generate markdown text for issue reporting
@available(iOS 13.0.0, *)
struct IssueInfoHelper {

    private static let issueDescTitle = "Issue Description"
    private static let pluginDescTitle = "Amplify Plugins Information"
    private static let envDescTitle = "Developer Environment Information"
    private static let deviceDescTitle = "Device Information"
    private static let logEntryTitle = "Logs"

    static func generateMarkdownForIssue(issue: IssueInfo) -> String {
        return """
        **\(issueDescTitle)**
        \(issue.getIssueDescription())

        **\(pluginDescTitle)**
        \(issue.getPluginInfoDescription())

        **\(envDescTitle)**
        \(issue.getEnvironmentInfoDescription())

        **\(deviceDescTitle)**
        \(issue.getDeviceInfoDescription())

        """
    }

}
