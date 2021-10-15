//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class SortedList<ModelType: Model> {
    var sortedModels: [ModelType]
    private let sortInput: [QuerySortDescriptor]?
    private let modelSchema: ModelSchema

    init(sortInput: [QuerySortDescriptor]?, modelSchema: ModelSchema) {
        self.sortedModels = []
        self.sortInput = sortInput
        self.modelSchema = modelSchema
    }

    /// Apply the incoming `model` to the sorted array based on the mutation type. This logic accounts for duplicate
    /// events since identical events may have different sources (local and remote). When the mutation type is delete,
    /// remove it if it exists in the array. When create/update, replace it if it exists in the array. If it does not
    /// exist in the array, then add the model to the array in the correct position.
    func apply(model: ModelType, mutationType: MutationEvent.MutationType) {
        if mutationType == MutationEvent.MutationType.delete {
            if let index = sortedModels.firstIndex(where: { $0.id == model.id }) {
                sortedModels.remove(at: index)
            }
        } else if let index = sortedModels.firstIndex(where: { $0.id == model.id }) {
            sortedModels[index] = model
        } else {
            add(model: model)
        }
    }

    /// Add the incoming `model` to the sorted array based on the sort input, or at the end if none is provided.
    /// Search for the index by comparing the incoming model with the current model in the binary search traversal.
    /// If the models are equal in terms of their sort order (comparator returns `nil`), then move onto the next sort
    /// input. If all sort comparators return `nil`, then the incoming model is equal to the current model on all
    /// sort inputs,  and inserting at the index will maintain the overall sort order.
    func add(model: ModelType) {
        guard let sortInputs = sortInput else {
            sortedModels.append(model)
            return
        }

        let index = sortedModels.binarySearch { existingModel in
            var sortOrder: Bool?
            var sortIndex: Int = 0
            while sortOrder == nil && sortIndex < sortInputs.endIndex {
                let sortInput = sortInputs[sortIndex]
                // `existingModel` is passed as left argument so the binarySearch's `predicate` criteria is met, ie.
                // if `existingModel` should come before the `model`, keep searching the right half of the array
                sortOrder = modelSchema.comparator(model1: existingModel, model2: model, sortBy: sortInput)
                sortIndex += 1
            }
            return sortOrder
        }

        sortedModels.insert(model, at: index)
    }
}

extension Array where Element: Model {

    /// Binary search an array that is expected to be sorted based on the `predicate`. The predicate should return
    /// `true` to continue searching on the right side by moving left index after the current middle index. Return
    /// `false` to continue searching on the left side by moving right index to the middle. If the `predicate` returns
    /// `nil` then the search is complete and return the index. There may be multiple models in the array that resolves
    /// to `nil`, however the index is immediately returned when found. The binary search is only possible on
    /// pre-sorted arrays to provide a O(log n) runtime and can be used to maintain the sorted array by inserting new
    /// models into the correct position.
    func binarySearch(predicate: (Element) -> Bool?) -> Index {
        var left = startIndex
        var right = endIndex
        while left != right {
            let middle = index(left, offsetBy: distance(from: left, to: right) / 2)
            guard let result = predicate(self[middle]) else {
                return middle
            }

            if result {
                left = index(after: middle)
            } else {
                right = middle
            }
        }
        return left
    }
}
