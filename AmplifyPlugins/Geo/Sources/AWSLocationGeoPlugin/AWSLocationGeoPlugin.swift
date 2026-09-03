//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

import AWSLocation

/// The AWSLocationPlugin implements the Geo APIs for Amazon Location
/// - Note: `@unchecked Sendable` to satisfy the `Sendable` requirement on `Plugin`. The service,
///   auth, and configuration properties are implicitly-unwrapped and populated during
///   `configure(using:)` before any client call can reach them.
public final class AWSLocationGeoPlugin: GeoCategoryPlugin, @unchecked Sendable {
    /// An instance of the AWS Location service
    var locationService: AWSLocationBehavior!

    /// An instance of the authentication service
    public var authService: AWSAuthServiceBehavior!

    /// A holder for the plugin configuration. This will be populated during the
    /// configuration phase, and is clearable by `reset()`.
    public var pluginConfig: AWSLocationGeoPluginConfiguration!

    /// The unique key of the plugin within the location category
    public let key: PluginKey = "awsLocationGeoPlugin"

    /// Instantiates an instance of the AWSLocationPlugin
    public init() {}

    /// Retrieve the escape hatch to perform actions directly on AWSLocation.
    ///
    /// - Returns: AWSLocation instance
    public func getEscapeHatch() -> LocationClient {
        locationService.getEscapeHatch()
    }
}

extension AWSLocationGeoPlugin: AmplifyVersionable { }
