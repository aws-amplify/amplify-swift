//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct GeoPluginErrorConstants {
    static let missingDefaultSearchIndex: GeoPluginErrorString = (
        "No default search index was found.",
        "Please ensure you have added search to your project before calling search functions.")

    static let missingDefaultMap: GeoPluginErrorString = (
        "No default map was found.",
        "Please ensure you have added maps to your project before calling map-related functions.")

    static let missingMaps: GeoPluginErrorString = (
        "No maps are available.",
        "Please ensure you have added maps to your project before calling map-related functions.")
    
    static let missingTracker: GeoPluginErrorString = (
        "No tracker available.",
        "Please ensure you have added tracker to your project before calling device position functions.")
    
    static let missingPermissions: GeoPluginErrorString = (
        "Location permissions not granted.",
        "Please ensure you have given approriate location permissions before starting device tracking.")
    
    static let errorInitializingLocalStore: GeoPluginErrorString = (
        "Unable to create local database for storing locations.",
        "This seems like a bug. Please report an issue on Amplify Swift repo.")
}

// Recovery Messages
extension GeoPluginErrorConstants {
    static let accessDenied: RecoverySuggestion = "Make sure the resource exists and the user has access."
    static let conflict: RecoverySuggestion = "Make sure the resource is unique."
    static let internalServer: RecoverySuggestion = "See underlying error for more details."
    static let resourceNotFound: RecoverySuggestion = "Make sure the resource exists."
    static let serviceQuotaExceeded: RecoverySuggestion = "Request a service quota increase."
    static let throttling: RecoverySuggestion = """
    Reduce the rate of service calls, retry throttled calls, or request a service quota increase.
    """
    static let validation: RecoverySuggestion = "Ensure the input satisfies the constraints of the requested resource."
}
