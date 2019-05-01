//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Internal utility extensions
extension Category {

    /// Returns the appropriate category-specific configuration section from an AmplifyConfiguration
    ///
    /// - Parameter amplifyConfiguration: The AmplifyConfiguration from which to return the category specific
    ///   configuration section
    /// - Returns: The category-specific configuration section, or nil if the configuration has no value for the section
    func categoryConfiguration(from amplifyConfiguration: AmplifyConfiguration) -> CategoryConfiguration? {
        switch self {
        case is AnalyticsCategory:
            return amplifyConfiguration.analytics
        case is APICategory:
            return amplifyConfiguration.api
        case is AuthCategory:
            return amplifyConfiguration.auth
        case is HubCategory:
            return amplifyConfiguration.hub
        case is LoggingCategory:
            return amplifyConfiguration.logging
        case is StorageCategory:
            return amplifyConfiguration.storage
        default:
            return nil
        }
    }

}
