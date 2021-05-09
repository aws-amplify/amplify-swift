//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AmplifyAPICategory: CategoryConfigurable {

    /// <#Description#>
    /// - Parameter configuration: <#configuration description#>
    /// - Throws: <#description#>
    func configure(using configuration: CategoryConfiguration?) throws {
        guard !isConfigured else {
            let error = ConfigurationError.amplifyAlreadyConfigured(
                "\(categoryType.displayName) has already been configured.",
                "Remove the duplicate call to `Amplify.configure()`"
            )
            throw error
        }

        try Amplify.configure(plugins: Array(plugins.values), using: configuration)

        isConfigured = true
    }

    /// <#Description#>
    /// - Parameter amplifyConfiguration: <#amplifyConfiguration description#>
    /// - Throws: <#description#>
    func configure(using amplifyConfiguration: AmplifyConfiguration) throws {
        try configure(using: categoryConfiguration(from: amplifyConfiguration))
    }

}
