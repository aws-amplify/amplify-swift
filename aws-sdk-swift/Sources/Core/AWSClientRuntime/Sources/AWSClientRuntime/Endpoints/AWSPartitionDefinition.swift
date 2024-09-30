//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// SDK guarantees sdk-partitions.json will be present
let partitionsFile = Bundle.module.url(forResource: "sdk-partitions", withExtension: "json")!

// First-time load will take longer but subsequent calls will use cached data
// swiftlint:disable:next force_try
public let awsPartitionJSON = try! String(contentsOf: partitionsFile, encoding: .utf8)
