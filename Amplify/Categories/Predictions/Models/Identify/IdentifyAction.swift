//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Identification criteria provided to
/// type parameter in identify() API
public enum IdentifyAction {
    case detectCelebrity
    case detectLabels(LabelType)
    case detectEntities
    case detectText(TextFormatType)
}

extension Predictions {
    public enum Identify {
        public struct Request<Output> {
            @_spi(PredictionsIdentifyRequestKind)
            public let kind: Kind
        }

        public struct Options {
            /// The default NetworkPolicy for the operation. The default value will be `auto`.
            public let defaultNetworkPolicy: DefaultNetworkPolicy
            /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
            /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
            /// key/values
            let pluginOptions: Any?

            public init(
                defaultNetworkPolicy: DefaultNetworkPolicy = .auto,
                uploadToRemote: Bool = false,
                pluginOptions: Any? = nil
            ) {
                self.defaultNetworkPolicy = defaultNetworkPolicy
                self.pluginOptions = pluginOptions

            }
        }
    }
}




fileprivate func liftContext<T>(_ input: T) -> T {
    input
}

extension Predictions.Identify.Request where Output == IdentifyLabelsResult {
    public static func labels(type: LabelType) -> Self {
        .init(kind: .detectLabels(type, .lift))
    }
}

extension Predictions.Identify.Request where Output == IdentifyCelebritiesResult {
    public static let celebrities = Self(
        kind: .detectCelebrities(.lift)
    )
}

extension Predictions.Identify.Request where Output == IdentifyEntitiesResult {
    public static let entities = Self(
        kind: .detectEntities(.lift)
    )
}

extension Predictions.Identify.Request where Output == IdentifyEntityMatchesResult {
    public static func entitiesFromCollection(withID collectionID: String) -> Self {
        .init(kind: .detectEntitiesCollection(collectionID, .lift))
    }
}

extension Predictions.Identify.Request where Output == IdentifyDocumentTextResult {
    public static func textInDocument(textFormatType: TextFormatType) -> Self {
        .init(kind: .detectTextInDocument(textFormatType, .lift))
    }
}

extension Predictions.Identify.Request where Output == IdentifyTextResult {
    public static let text = Self(
        kind: .detectText(.lift)
    )
}

extension Predictions.Identify.Request {
    @_spi(PredictionsIdentifyRequestKind)
    public enum Kind {
        public typealias Lifting<T> = ((T) -> Output, (Output) -> T)

        case detectCelebrities(
            Lift<IdentifyCelebritiesResult, Output>
        )

        case detectEntities(
            Lift<IdentifyEntitiesResult, Output>
        )

        case detectEntitiesCollection(
            String,
            Lift<IdentifyEntityMatchesResult, Output>
        )

        case detectLabels(
            LabelType,
            Lift<IdentifyLabelsResult, Output>
        )

        case detectTextInDocument(
            TextFormatType,
            Lift<IdentifyDocumentTextResult, Output>
        )

        case detectText(
            Lift<IdentifyTextResult, Output>
        )
    }
}

extension Predictions.Identify.Request.Kind {
    public struct Lift<
        SpecificOutput,
        GenericOutput
    > {
        public let outputSpecificToGeneric: (SpecificOutput) -> GenericOutput
        public let outputGenericToSpecific: (GenericOutput) -> SpecificOutput
    }
}

extension Predictions.Identify.Request.Kind.Lift where GenericOutput == SpecificOutput {
    static var lift: Self {
        .init(
            outputSpecificToGeneric: { $0 },
            outputGenericToSpecific: { $0 }
        )
    }
}
