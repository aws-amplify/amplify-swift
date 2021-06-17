//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Different entity types detected in a text as a result of
/// interpret() API
public enum EntityType: String {
    case commercialItem
    case date
    case event
    case location
    case organization
    case other
    case person
    case quantity
    case title
    case unknown
}
