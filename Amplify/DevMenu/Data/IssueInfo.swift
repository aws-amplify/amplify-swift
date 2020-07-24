//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Struct consisting of information required to report an issue
@available(iOS 13.0.0, *)
struct IssueInfo {

    private var includeEnvironmentInfo: Bool
    private var includeDeviceInfo: Bool
    private var includeLogs: Bool

    private var issueDescription: String
    private var environmentInfoItems: [EnvironmentInfoItem] = []
    private var pluginInfoItems: [PluginInfoItem] = []
    private var deviceInfoItems: [DeviceInfoItem] = []
    private var logEntryItems: [LogEntryItem] = []

    private let infoNotAvailable = "Information not available"

    init(issueDescription: String, includeEnvInfo: Bool, includeDeviceInfo: Bool, includeLogs: Bool) {
        self.issueDescription = issueDescription.isEmpty ? infoNotAvailable : issueDescription
        self.includeEnvironmentInfo = includeEnvInfo
        self.includeDeviceInfo = includeDeviceInfo
        self.includeLogs = includeLogs
        initializeEnvironmentInfo()
        initializePluginInfo()
        initializeDeviceInfo()
        initializeLogEntryInfo()
    }

    private mutating func initializeEnvironmentInfo() {
        if includeEnvironmentInfo {
            environmentInfoItems = EnvironmentInfoHelper.fetchDeveloperInformationFromJson(
                filename: EnvironmentInfoHelper.environmentInfoSourceFileName)
        }
    }

    private mutating func initializePluginInfo() {
        if includeEnvironmentInfo {
            pluginInfoItems = PluginInfoHelper.getPluginInformation()
        }
    }

    private mutating func initializeDeviceInfo() {
        if includeDeviceInfo {
            deviceInfoItems = DeviceInfoHelper.getDeviceInformation()
        }
    }

    private mutating func initializeLogEntryInfo() {
        if includeLogs {
            logEntryItems = LogEntryHelper.getLogHistory()
        }
    }

    /// Returns issue description entered by customer if any
    func getIssueDescription() -> String {
        return issueDescription
    }

    /// Returns environment information of customer in the form of text
    func getEnvironmentInfoDescription() -> String {
        return getItemsDescription(items: environmentInfoItems)
    }

    /// Returns plugin information in the form of text
    func getPluginInfoDescription() -> String {
        return getItemsDescription(items: pluginInfoItems)
    }

    /// Returns device information in the form of text
    func getDeviceInfoDescription() -> String {
        return getItemsDescription(items: deviceInfoItems)
    }

    /// Returns logs information in the form of text
    func getLogEntryDescription() -> String {
         var description: String

        if logEntryItems.isEmpty {
             description = infoNotAvailable
         } else {
             description = ""
            for item in logEntryItems {
                description.append("\(LogEntryHelper.dateString(from: item.timeStamp)) "
                    + "\(item.logLevelString) "
                    + "\(item.message) \n")
             }
         }

         return description
     }

    private func getItemsDescription(items: [InfoItemProvider]) -> String {
        var description: String

        if items.isEmpty {
            description = infoNotAvailable
        } else {
            description = ""
            for item in items {
                description.append("\(item.displayName) - \(item.information) \n")
            }
        }

        return description
    }
}
