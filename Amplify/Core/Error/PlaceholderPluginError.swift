////
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

/// Error used by plugin placeholders.
///
/// See: [PlaceholderPluginError.init(pluginName:selector:)](x-source-tag://PlaceholderPluginError.init_pluginName_selector)
///
/// - Tag: PlaceholderPluginError
struct PlaceholderPluginError: AmplifyError {

    var errorDescription: ErrorDescription
    var recoverySuggestion: RecoverySuggestion
    var underlyingError: Error?

    /// - Tag: PlaceholderPluginError.init_errorDescription_recoverySuggestion_error
    init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion, error: Error) {
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
        self.underlyingError = error
    }

    /// - Tag: PlaceholderPluginError.init_pluginName_selector
    init(pluginName: String, selector: String) {
        self.errorDescription = "A \(pluginName) value must first be provided using `Amplify.add(plugin:)` before calling `\(selector)`."
        self.recoverySuggestion = "Pass a \(pluginName) instance to Amplify.add(plugin:)"
        self.underlyingError = nil
    }
}
