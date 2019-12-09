//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Represents a list of models as a graph or a set of trees, each one rooted at a "parent" model with no upstream
/// dependencies
final class ModelGraphs {
    let models: [Model.Type]
    let nodes: [String: DirectedGraphNode<Model.Type>]
    let roots: [DirectedGraphNode<Model.Type>]

    init(models: [Model.Type]) {
        self.models = models
        self.nodes = ModelGraphs.makeNodesByModelName(from: models)
        ModelGraphs.connect(nodes)
        self.roots = ModelGraphs.getRoots(from: nodes)
    }

    private static func makeNodesByModelName(from models: [Model.Type]) -> [String: DirectedGraphNode<Model.Type>] {
        let nodes = models.reduce([String: DirectedGraphNode<Model.Type>]()) { curr, next in
            var newValue = curr
            newValue[next.modelName] = DirectedGraphNode(value: next)
            return newValue
        }
        return nodes
    }

    private static func connect(_ unconnectedNodes: [String: DirectedGraphNode<Model.Type>]) {
        for node in unconnectedNodes.values {
            let modelType = node.value
            let associations = modelType
                .schema
                .fields
                .map { $0.value }
                .map(ModelGraphs.associationData(for:))
                .compactMap { $0 }

            for (association, associatedModel) in associations {
                connectModelAssociation(node: node,
                                        association: association,
                                        associatedModel: associatedModel,
                                        nodesByName: unconnectedNodes)
            }
        }
    }

    private static func associationData(for modelField: ModelField)
        -> (association: ModelAssociation, associatedModel: Model.Type)? {
            guard let association = modelField.association,
                let associatedModel = modelField.associatedModel else {
                    return nil
            }
            return (association: association, associatedModel: associatedModel)
    }

    /// Connects the node to its target based on the relationship specified in `association`.
    ///
    /// This function only looks at `.belongsTo` associations, and adds upstream/downstream based on
    /// that. The implications of this are:
    /// - many-to-many associations are not directly modeled, but instead will traverse the
    ///   intermediate "join" model: `Book <- BookAuthor -> Author`
    /// - one-to-many associations are modeled with the "one" side of the association referencing
    ///   the "many" side as a "downstream" member; conversely, the "many" side of the association shows
    ///   the "one" side as an "upstream" member: `Post <- Comment`
    /// - one-to-one associations require that the "owner" side has an optional field with a `.hasOne`
    ///   association with its peer; the other side has a required `.belongsTo` association:
    ///   `UserAccount <- UserProfile`
    private static func connectModelAssociation(node: DirectedGraphNode<Model.Type>,
                                                association: ModelAssociation,
                                                associatedModel: Model.Type,
                                                nodesByName: [String: DirectedGraphNode<Model.Type>]) {
        guard case .belongsTo = association else {
            return
        }

        guard let target = nodesByName[associatedModel.modelName] else {
            return
        }

        node.addUpstream(target)
        target.addDownstream(node)
    }

    private static func getRoots(from connectedNodes: [String: DirectedGraphNode<Model.Type>])
        -> [DirectedGraphNode<Model.Type>] {
            var visited = Set<DirectedGraphNode<Model.Type>>()
            var roots = Set<DirectedGraphNode<Model.Type>>()

            // For a set of nodes where all elements are guaranteed to belong to the same graph, we could
            // simplify this to a single BFS-style traversal. But since we have no guarantee that the
            // models are connected, we'll loop through each node and use it as a candidate for a search,
            // with a short-circuit in the form of a global `visited` set
            for node in connectedNodes.values {
                guard !visited.contains(node) else {
                    continue
                }

                var queue = [node]
                var current: DirectedGraphNode<Model.Type> = node
                while !queue.isEmpty {
                    current = queue.removeFirst()
                    visited.insert(current)
                    // Don't need to look at downstream nodes, since we know they're not roots
                    current.downstream.forEach { visited.insert($0) }

                    if current.upstream.isEmpty {
                        roots.insert(current)
                    } else {
                        queue.append(contentsOf: current.upstream)
                    }
                }

            }

            return Array(roots)
    }
}

extension ModelGraphs: CustomDebugStringConvertible {
    var debugDescription: String {
        var descriptions = [String]()
        for (modelName, node) in nodes {
            descriptions.append("\(modelName): \(node)")
        }
        return descriptions.joined(separator: "\n")
    }

}

final class DirectedGraphNode<Value> {

    let id: UUID
    let value: Value
    var upstream: [DirectedGraphNode<Value>]
    var downstream: [DirectedGraphNode<Value>]

    init(value: Value) {
        self.id = UUID()
        self.value = value
        self.upstream = []
        self.downstream = []
    }

    func addUpstream(_ value: DirectedGraphNode<Value>) {
        upstream.append(value)
    }

    func addDownstream(_ value: DirectedGraphNode<Value>) {
        downstream.append(value)
    }
}

extension DirectedGraphNode: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        \(String(describing: value)) \
        upstream: \(upstream.map { $0.displayName }) \
        downstream: \(downstream.map { $0.displayName })
        """
    }

    var displayName: String {
        String(describing: value)
    }
}

extension DirectedGraphNode: Hashable {
    static func == (lhs: DirectedGraphNode<Value>, rhs: DirectedGraphNode<Value>) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}
