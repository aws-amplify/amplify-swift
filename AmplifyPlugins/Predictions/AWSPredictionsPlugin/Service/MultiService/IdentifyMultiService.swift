//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@_spi(PredictionsIdentifyRequestKind) import Amplify

class IdentifyMultiService<Output> {

    let request: Predictions.Identify.Request<Output>
    let url: URL
    weak var coreMLService: CoreMLPredictionBehavior?
    weak var predictionsService: AWSPredictionsService?

    init(
        request: Predictions.Identify.Request<Output>,
        url: URL,
        coreMLService: CoreMLPredictionBehavior?,
        predictionsService: AWSPredictionsService?
    ) {
        self.request = request
        self.url = url
        self.coreMLService = coreMLService
        self.predictionsService = predictionsService
    }

    func onlineResult() async throws -> Output {
        // TODO: Update Error TypeKind
        guard let onlineService = predictionsService else {
            let message = IdentifyMultiServiceErrorMessage.onlineIdentifyServiceNotAvailable.errorDescription
            let recoveryMessage = IdentifyMultiServiceErrorMessage.onlineIdentifyServiceNotAvailable.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            throw predictionError
        }

        switch request.kind {
        case let .detectText(lift):
            let result = try await onlineService.detectPlainText(image: url)
            return lift.outputSpecificToGeneric(result)

        case let .detectTextInDocument(formatType, lift):
            let result = try await onlineService.analyzeDocument(
                image: url,
                features: formatType.textractServiceFormatType
            )
            return lift.outputSpecificToGeneric(result)

        case let .detectEntitiesCollection(collectionID, lift):
            let result = try await onlineService.detectEntitiesCollection(
                image: url,
                collectionID: collectionID
            )
            return lift.outputSpecificToGeneric(result)

        case .detectEntities(let lift):
            let result = try await onlineService.detectEntities(image: url)
            return lift.outputSpecificToGeneric(result)

        case let .detectCelebrities(lift):
            let result = try await onlineService.detectCelebrities(image: url)
            return lift.outputSpecificToGeneric(result)

        case let .detectLabels(labelType, lift):
            let result = try await onlineService.detectLabels(image: url, type: labelType)
            return lift.outputSpecificToGeneric(result)
        }
    }



    func offlineResult() async throws -> Output {
        guard let offlineService = coreMLService else {
            let message = IdentifyMultiServiceErrorMessage.onlineIdentifyServiceNotAvailable.errorDescription
            let recoveryMessage = IdentifyMultiServiceErrorMessage.onlineIdentifyServiceNotAvailable.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            throw predictionError
        }

        let result = try await offlineService.identify(request, in: url)
        return result
    }

    func mergeResults(
        offline: Output,
        online: Output
    ) -> Output {
        switch request.kind {
        case let .detectLabels(_, lift):
            let result = mergeLabelResult(
                offline: lift.outputGenericToSpecific(offline),
                online: lift.outputGenericToSpecific(online)
            )

            return lift.outputSpecificToGeneric(result)

        case let .detectText(lift):
            let result = mergeTextResult(
                offline: lift.outputGenericToSpecific(offline),
                online: lift.outputGenericToSpecific(online)
            )
            return lift.outputSpecificToGeneric(result)

        default:
            return online
        }
    }

    private func mergeTextResult(
        offline: IdentifyTextResult,
        online: IdentifyTextResult
    ) -> IdentifyTextResult {
        // If the online `IdentifyTextResult` doesn't have
        // any `identifiedLines`, replace the `identifiedLines`
        // property with the offline `IdentifyTextResult`s value.
        guard let onlineLines = online.identifiedLines else {
            return IdentifyTextResult(
                fullText: online.fullText,
                words: online.words,
                rawLineText: online.rawLineText,
                identifiedLines: offline.identifiedLines
            )
        }

        guard let offlineLines = offline.identifiedLines else {
            return online
        }

        var combinedLines = Set<IdentifiedLine>()
        let onlineLineSet = Set(onlineLines)
        let offlineLineSet = Set(offlineLines)

        combinedLines = onlineLineSet.intersection(offlineLineSet)
        combinedLines.formUnion(offlineLineSet)
        combinedLines.formUnion(onlineLineSet)

        // offline only returns identified lines,
        // so merging them with the other properties from
        // online is the merged result
        return IdentifyTextResult(
            fullText: online.fullText,
            words: online.words,
            rawLineText: online.rawLineText,
            identifiedLines: Array(combinedLines)
        )

    }

    private func mergeLabelResult(
        offline: IdentifyLabelsResult,
        online: IdentifyLabelsResult
    ) -> IdentifyLabelsResult {
        let onlineLabelSet = Set(online.labels)
        let offlineLabelSet = Set(offline.labels)
        let intersection = onlineLabelSet.intersection(offlineLabelSet)

        var combinedLabels = Set<Label>()
        for label in intersection {
            let onlineIndex = onlineLabelSet.firstIndex(of: label)!
            let offlineIndex = offlineLabelSet.firstIndex(of: label)!
            let onlineLabel = onlineLabelSet[onlineIndex]
            let offlineLabel = offlineLabelSet[offlineIndex]
            let labelWithHigherConfidence = onlineLabel
                .higherConfidence(compareTo: offlineLabel)
            combinedLabels.insert(labelWithHigherConfidence)
        }

        combinedLabels.formUnion(onlineLabelSet)
        combinedLabels.formUnion(offlineLabelSet)

        return IdentifyLabelsResult(
            labels: Array(combinedLabels),
            unsafeContent: online.unsafeContent
        )
    }
}

//class IdentifyMultiService: MultiServiceBehavior {
//
//    typealias Event = PredictionsEvent<IdentifyResult, PredictionsError>
//    typealias IdentifyEventHandler = (Event) -> Void
//
//    weak var coreMLService: CoreMLPredictionBehavior?
//    weak var predictionsService: AWSPredictionsService?
//    var request: PredictionsIdentifyRequest!
//
//    init(
//        coreMLService: CoreMLPredictionBehavior?,
//        predictionsService: AWSPredictionsService?
//    ) {
//        self.coreMLService = coreMLService
//        self.predictionsService = predictionsService
//    }
//
//    func setRequest(_ request: PredictionsIdentifyRequest) {
//        self.request = request
//    }
//
//    func fetchOnlineResult() async throws -> IdentifyResult {
//        guard let onlineService = predictionsService else {
//            let message = IdentifyMultiServiceErrorMessage.onlineIdentifyServiceNotAvailable.errorDescription
//            let recoveryMessage = IdentifyMultiServiceErrorMessage.onlineIdentifyServiceNotAvailable.recoverySuggestion
//            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
//            throw predictionError
//        }
//
//        switch request.identifyType {
//        case .detectCelebrity:
//            return try await onlineService.detectCelebrities(image: request.image)
//        case .detectText(let formatType):
//            return try await onlineService.detectText(image: request.image, format: formatType)
//        case .detectLabels(let labelType):
//            return try await onlineService.detectLabels(image: request.image, type: labelType)
//        case .detectEntities:
//            return try await onlineService.detectEntities(image: request.image)
//        }
//    }
//
//    func fetchOfflineResult() async throws -> IdentifyResult {
//        guard let offlineService = coreMLService else {
//            let message = IdentifyMultiServiceErrorMessage.offlineIdentifyServiceNotAvailable.errorDescription
//            let recoveryMessage = IdentifyMultiServiceErrorMessage.offlineIdentifyServiceNotAvailable.recoverySuggestion
//            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
//            throw predictionError
//        }
//
//        // TODO: Update to new API
//        fatalError()
//
////        return try await offlineService.identify(request, in: request.image)
//    }
//
//    // MARK: -
//    func mergeResults(
//        offlineResult: IdentifyResult?,
//        onlineResult: IdentifyResult?
//    ) async throws -> IdentifyResult {
//
//        if offlineResult == nil && onlineResult == nil {
//            let message = IdentifyMultiServiceErrorMessage.noResultIdentifyService.errorDescription
//            let recoveryMessage = IdentifyMultiServiceErrorMessage.noResultIdentifyService.recoverySuggestion
//            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
//            throw predictionError
//        }
//
//        guard let finalOfflineResult = offlineResult else {
//            // We are sure that the value will be non-nil at this point.
//            return onlineResult! // TODO: Does ^ make sense???
//        }
//
//        guard let finalOnlineResult = onlineResult else {
//            return finalOfflineResult
//        }
//
//        if let onlineLabelResult = finalOnlineResult as? IdentifyLabelsResult,
//            let offlineLabelResult = finalOfflineResult as? IdentifyLabelsResult {
//            let mergedResult = mergeLabelResult(
//                onlineLabelResult: onlineLabelResult,
//                offlineLabelResult: offlineLabelResult
//            )
//
//            return mergedResult
//        }
//        if let onlineTextResult = finalOnlineResult as? IdentifyTextResult,
//            let offlineTextResult = finalOfflineResult as? IdentifyTextResult {
//            let mergedResult = mergeTextResult(
//                onlineTextResult: onlineTextResult,
//                offlineTextResult: offlineTextResult
//            )
//            return mergedResult
//        }
//
//        // At this point we decided not to merge the result and return the non-nil online
//        // result back.
//        return finalOnlineResult
//    }
//
//    func mergeLabelResult(onlineLabelResult: IdentifyLabelsResult,
//                          offlineLabelResult: IdentifyLabelsResult) -> IdentifyLabelsResult {
//        var combinedLabels = Set<Label>()
//
//        let onlineLabelSet = Set<Label>(onlineLabelResult.labels)
//        let offlineLabelSet = Set<Label>(offlineLabelResult.labels)
//
//        // first find the labels that are the same
//        let intersectingLabels = onlineLabelSet.intersection(offlineLabelSet)
//        // loop through to find higher confidences and retain those labels and add to final result
//        for label in intersectingLabels {
//            let onlineIndex = onlineLabelSet.firstIndex(of: label)!
//            let offlineIndex = offlineLabelSet.firstIndex(of: label)!
//            let onlineLabel = onlineLabelSet[onlineIndex]
//            let offlineLabel = offlineLabelSet[offlineIndex]
//            let labelWithHigherConfidence = onlineLabel.higherConfidence(compareTo: offlineLabel)
//            combinedLabels.insert(labelWithHigherConfidence)
//        }
//
//        // get the differences
//        // leaving here for performance comparison
//        // let differingLabels = Array(onlineLabelSet.symmetricDifference(offlineLabelSet))
//        // combinedLabels.append(contentsOf: differingLabels)
//        combinedLabels = combinedLabels.union(onlineLabelSet)
//        combinedLabels = combinedLabels.union(offlineLabelSet)
//
//        return IdentifyLabelsResult(labels: Array(combinedLabels),
//                                    unsafeContent: onlineLabelResult.unsafeContent ?? nil)
//
//    }
//
//    func mergeTextResult(onlineTextResult: IdentifyTextResult,
//                         offlineTextResult: IdentifyTextResult) -> IdentifyTextResult {
//
//        guard let onlineLines = onlineTextResult.identifiedLines else {
//            return IdentifyTextResult(fullText: onlineTextResult.fullText,
//                                      words: onlineTextResult.words,
//                                      rawLineText: onlineTextResult.rawLineText,
//                                      identifiedLines: offlineTextResult.identifiedLines)
//        }
//
//        guard let offlineLines = offlineTextResult.identifiedLines else {
//            return onlineTextResult
//        }
//        var combinedLines = Set<IdentifiedLine>()
//        let onlineLineSet = Set<IdentifiedLine>(onlineLines)
//        let offlineLineSet = Set<IdentifiedLine>(offlineLines)
//
//        combinedLines = onlineLineSet.intersection(offlineLineSet)
//        combinedLines = combinedLines.union(offlineLineSet)
//        combinedLines = combinedLines.union(onlineLineSet)
//
//        // offline result doesn't return anything except identified lines so
//        // merging them plus the other stuff from online is a merged result
//        return IdentifyTextResult(fullText: onlineTextResult.fullText,
//                                  words: onlineTextResult.words,
//                                  rawLineText: onlineTextResult.rawLineText,
//                                  identifiedLines: Array(combinedLines))
//    }
//}

extension Label: Hashable {

    public static func == (lhs: Label, rhs: Label) -> Bool {
        return lhs.name.lowercased() == rhs.name.lowercased()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name.lowercased())
    }

    func higherConfidence(compareTo: Label) -> Label {
        guard let firstMetadata = metadata,
            let secondMetadata = compareTo.metadata else {
                return self
        }
        return max(firstMetadata, secondMetadata) == firstMetadata ? self : compareTo
    }
}

extension LabelMetadata: Equatable, Comparable {

    public static func == (lhs: LabelMetadata, rhs: LabelMetadata) -> Bool {
        let value = lhs.confidence == rhs.confidence
        return value
    }

    public static func < (lhs: LabelMetadata, rhs: LabelMetadata) -> Bool {
        let value = lhs.confidence < rhs.confidence
        return value
    }
}

extension IdentifiedLine: Hashable {

    public static func == (lhs: IdentifiedLine, rhs: IdentifiedLine) -> Bool {
        return lhs.text == rhs.text
            && lhs.boundingBox.intersects(rhs.boundingBox)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
    }
}
