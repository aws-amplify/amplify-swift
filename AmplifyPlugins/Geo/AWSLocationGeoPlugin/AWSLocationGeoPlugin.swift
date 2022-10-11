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
public final class AWSLocationGeoPlugin: GeoCategoryPlugin {
    /// An instance of the AWS Location service
    var locationService: AWSLocationBehavior!

    /// An instance of `DeviceTrackingBehavior` for device tracking
    static var deviceTracker: DeviceTrackingBehavior?
    
    /// An instance of `AWSLocationStoreBehavior` for storing locations
    var locationStore: AWSLocationStoreBehavior!
    
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
