//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


/// This class represents a lazy reference to a `Model`, meaning that the reference
/// may or may not exist at instantiation time.
///
/// The default implementation only handles in-memory data, therefore `get()` and
/// `require()` will simply return the current `reference`.
class LazyReference<ModelType: Model> : Codable {

    /// The model reference.
    private var reference: ModelType?

    init(_ reference: ModelType? = nil) {
        self.reference = reference
    }

    /// This function is responsible for retrieving the model reference. In the default
    /// implementation this means simply returning the existing `reference`, but different
    /// storage mechanisms can implement their own logic to fetch data,
    /// e.g. from DataStore's SQLite or AppSync.
    ///
    /// - Returns: the model `reference`, if it exists.
    func get() async throws -> ModelType? {
        return reference
    }

    /// The equivalent of `get()` but aimed to retrieve references that are considered
    /// non-optional. However, referential integrity issues and/or availability constraints
    /// might affect how required data is fetched. In such scenarios the implementation
    /// must throw an error to communicate to developers why required data could not be fetched.
    ///
    /// - Throws: an error of type `DataError` when the data marked as required cannot be retrieved.
    func require() async throws -> ModelType {
        guard let ref = try await get() else {
            throw DataError.dataUnavailable
        }
        return ref
    }

    // MARK: Codable implementation

    /// Decodable implementation is delegated to the underlying `self.reference`.
    required init(from decoder: Decoder) throws {
        self.reference = try ModelType.init(from: decoder)
    }

    /// Encodable implementation is delegated to the underlying `self.reference`.
    func encode(to encoder: Encoder) throws {
        try self.reference.encode(to: encoder)
    }

}
