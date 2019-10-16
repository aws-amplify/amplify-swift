//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: all indexable types

/*
 Only Classes and Strucs that conform to this type can be indexed
 */
public protocol IndexableType {}

extension Date: IndexableType {}
extension Int: IndexableType {}
extension String: IndexableType {}

// extension IndexableType {
//    public static undefined() {
//        self.init
//    }
// }

// MARK: Index Struct

/*
 Represents the configuration of a data storage index.
 */
public struct Index {
//    public typealias IndexKey = PartialKeyPath<T>

    public let keys: [CodingKey]
    public let name: String?
    public let sortBy: CodingKey?
}

// MARK: Protocol declaration

/*
 Marks a `Model` as a index-aware entity. This protocol adds index-related metadata
 and utilities.
 */
public protocol Indexable {
    typealias Indexes = [Index]

    static var indexes: Indexes { get }

    static func index(name: String?, sortBy sortKey: CodingKey?, forKeys keys: CodingKey...) -> Index
}
