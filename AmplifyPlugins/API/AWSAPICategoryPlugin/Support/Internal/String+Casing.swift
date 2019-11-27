//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension String {

    /// Converts a "camelCase" value to "PascalCase". This is a very simple
    /// and naive implementation that assumes the input as a "camelCase" value
    /// and won't perform complex conversions, such as from "snake_case"
    /// or "dash-case" to "PascalCase".
    ///
    /// - Note: this method simply transforms the first character to uppercase.
    ///
    /// - Returns: a string in "PascalCase" converted from "camelCase"
    internal func pascalCased() -> String {
        return prefix(1).uppercased() + dropFirst()
    }

    /// Converts a "PascalCase" value to "camcelCase". This is a very simple
    /// and naive implementation that assumes the input as a "PascalCase" value
    /// and won't perform complex conversions, such as from "snake_case"
    /// or "dash-case" to "pascalCase".
    ///
    /// - Note: this method simply transforms the first character to lowercase.
    ///
    /// - Returns: a string in "pascalCase" converted from "CamelCase"
    internal func camelCased() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
}
