//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class List<M: PersistentModel>: Collection, Codable {

    public typealias Index = Int
    public typealias Element = M

    var elements: [M] = []

    public init(_ elements: [M] = []) {
        self.elements = elements
    }

    public subscript(index: Index) -> Iterator.Element {
        return elements[index]
    }

    public var startIndex: Int {
        elements.startIndex
    }

    public var endIndex: Int {
        elements.endIndex
    }

    public func index(after index: Int) -> Int {
        elements.index(after: index)
    }

    // MARK: - Codable

    required public init(from decoder: Decoder) throws {
        self.elements = try [M].init(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }

}

public class ConnectedList<M: PersistentModel>: List<M> {

    typealias IdResolver = () -> String?

    enum State: String {
        case unitialized
        case loaded
    }

    let resolveId: IdResolver
    let connectedProperty: ModelProperty
    var state: State

    internal init(idResolver resolveId: @escaping IdResolver, connectedProperty: ModelProperty) {
        self.resolveId = resolveId
        self.connectedProperty = connectedProperty
        self.state = .unitialized
        super.init([M]())
    }

    required public init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override public subscript(index: Index) -> Iterator.Element {
        elements = lazyLoad()
        return super[index]
    }

    public __consuming func makeIterator() -> IndexingIterator<List<M>> {
        elements = lazyLoad()
        return IndexingIterator(_elements: self)
    }

    internal func lazyLoad() -> [M] {
        switch state {
        case .unitialized:
            var loadedElements = elements
            if let id = resolveId() {
                let semaphore = DispatchSemaphore(value: 1)
                semaphore.wait()
//                DataStore.query() {
//                    elements = $0
//                    semaphore.signal()
//                }
            }
            return loadedElements
        case .loaded:
            return elements
        }
    }

}

extension Array where Element == ModelProperty {

    func connected(byName name: String) -> ModelProperty? {
        return first {
            // TODO match connected attribute name
            $0.metadata.isConnected
        }
    }
}

extension Model where Self: ModelMetadata {

    public func list<M: PersistentModel>(connectedTo property: ModelProperty?) -> List<M> {
        let modelType = type(of: self)

        // resolve the connected property
        var connectedProperty = property
        if connectedProperty == nil {
            let connectedProperties = M.properties.filter {
                $0.metadata.isConnected && $0.metadata.connectedModel == modelType
            }
            if connectedProperties.isEmpty {
                preconditionFailure("")
            }
            if connectedProperties.count > 1 {
                preconditionFailure("")
            }
            connectedProperty = connectedProperties.first!
        }

        func getId() -> String? {
            let id = self[modelType.primaryKey.metadata.key]
            if id != nil {
                guard let id = id as? String else {
                    preconditionFailure("")
                }
                return id
            }
            return nil
        }

        // TODO create ConnectedList instance
        return List<M>()
    }

}
