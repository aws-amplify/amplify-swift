//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class SyncEnabledGraphQLDocument<Document: GraphQLDocument>: GraphQLDocument {

    private let graphQLDocument: Document
    private let version: Int?

    init(graphqQLDocument: Document, version: Int? = nil) {
        self.graphQLDocument = graphqQLDocument
        self.version = version
    }

    public var documentType: GraphQLDocumentType {
        graphQLDocument.documentType
    }

    public var name: String {
        graphQLDocument.name
    }

    public var modelType: Model.Type {
        graphQLDocument.modelType
    }

    public var stringValue: String {
        let selectionSetString = selectionSetFields.map { $0.toString() }.joined(separator: "\n    ")
        if let inputTypes = inputTypes, let inputParameters = inputParameters {
            return """
            \(documentType) \(name.pascalCased())(\(inputTypes)) {
              \(name)(\(inputParameters)) {
                \(selectionSetString)
              }
            }
            """
        }

        return """
        \(documentType) \(name.pascalCased()) {
          \(name) {
            \(selectionSetString)
          }
        }
        """
    }

    public var inputTypes: String? {
        graphQLDocument.inputTypes
    }

    public var inputParameters: String? {
        graphQLDocument.inputParameters
    }

    public var variables: [String: Any] {
        var variables = graphQLDocument.variables

        if let version = version, var input = variables["input"] as? [String: Any] {
            input.updateValue(version, forKey: "_version")
            variables["input"] = input
        }

        return variables
    }

    public var selectionSetFields: [SelectionSetField] {
        if graphQLDocument.name.contains("list") {
            return [SelectionSetField(value: "items",
                                      innerFields: modelType.schema.graphQLFields.toSelectionSets(syncEnabled: true)),
                    SelectionSetField(value: "nextToken")]
        }

        return modelType.schema.graphQLFields.toSelectionSets(syncEnabled: true)
    }
}
