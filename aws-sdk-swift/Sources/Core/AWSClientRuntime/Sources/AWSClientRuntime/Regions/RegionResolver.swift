//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol RegionResolver {
    var providers: [RegionProvider] {get}
    func getRegion() async -> String?
}
