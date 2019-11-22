//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class List<M: Model>: Collection, Codable, ExpressibleByArrayLiteral {

    public typealias Index = Int
    public typealias Element = M

    public typealias ArrayLiteralElement = M

    private var array: [M]
    private var id: Model.Identifier?
    private var sourceField: ModelField?

    private var limit: Int = 10

    init(_ elements: [M],
         id: Model.Identifier? = nil,
         sourceField: ModelField? = nil) {
        self.array = elements
        self.id = id
        self.sourceField = sourceField
    }

    required convenience public init(arrayLiteral elements: M...) {
        self.init(elements)
    }

    public var startIndex: Index {
        array.startIndex
    }

    public var endIndex: Index {
        array.endIndex
    }

    public func index(after index: Index) -> Index {
        array.index(after: index)
    }

    public subscript(position: Int) -> M {
        precondition(indices.contains(position), "out of bounds")
        return array[position]
    }

    public func limit(_ limit: Int) -> Self {
        self.limit = limit
        return self
    }

    public func load() {
        guard let id = self.id, let sourceField = self.sourceField else {
            return
        }

        let semaphore = DispatchSemaphore(value: 0)

        guard let associatedField = sourceField.associatedField else {
            preconditionFailure("")
        }

        let name = associatedField.targetName ?? "\(associatedField.name)Id"
        let predicate = { field(name) == id }
        Amplify.DataStore.query(Element.self, where: predicate) {
            switch $0 {
            case .result(let elements):
                self.array = elements
                semaphore.signal()
            case .error(let error):
                semaphore.signal()
                // TODO should we crash? or silently fail and warn? Hub event?
                fatalError(error.errorDescription)
            }
        }
        semaphore.wait()
    }

    // MARK: - Codable

    enum JSONCodingKeys: CodingKey {
        case associatedId
        case associatedFieldName
    }

    required convenience public init(from decoder: Decoder) throws {
//        decoder.container(keyedBy: )
//        print(decoder.userInfo)
//        print(try decoder.singleValueContainer())
//        print(try decoder.unkeyedContainer())
//        print(decoder.codingPath)
        let json = try JSONValue.init(from: decoder)
        switch json {
        case .array:
            let elements = try [Element].init(from: decoder)
            self.init(elements)
        case .object(let list):
            // TODO
            print("-------------------")
            print(list)
            self.init([Element].init())
        default:
            self.init([Element].init())
        }
    }

    public func encode(to encoder: Encoder) throws {
        try array.encode(to: encoder)
    }

}

extension Model {

    public static func listOf(id: String, field: ModelField) -> List<Self> {
        return List<Self>([], id: id, sourceField: field)
    }
}
