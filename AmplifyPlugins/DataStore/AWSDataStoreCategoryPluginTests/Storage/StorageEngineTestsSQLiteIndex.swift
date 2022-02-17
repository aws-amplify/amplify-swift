//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class StorageEngineTestsSQLiteIndex: StorageEngineTestsBase {
    var connectionWithIndex: Connection!
    var storageEngineWithIndex: StorageEngine!
    var storageAdapterWithIndex: SQLiteStorageEngineAdapter!
    var syncEngineWithIndex: MockRemoteSyncEngine!
    let validAPIPluginKey = "MockAPICategoryPlugin"
    let validAuthPluginKey = "MockAuthCategoryPlugin"

    // number of records to be created
    let numberOfRecords = 100

    // number of iterations over which a query time is averaged out
    let iterations = 10

    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .warn
        setUpStorageEngine()
    }

    func setUpStorageEngine() {
        do {
            // create storage adapter without SQLite indexes for secondary indexes present in Model schema
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            storageAdapter.shouldCreateSQLiteIndexes = false
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)
            syncEngine = MockRemoteSyncEngine()
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)

            connectionWithIndex = try Connection(.inMemory)
            storageAdapterWithIndex = try SQLiteStorageEngineAdapter(connection: connectionWithIndex)
            try storageAdapterWithIndex.setUp(modelSchemas: StorageEngine.systemModelSchemas)
            syncEngineWithIndex = MockRemoteSyncEngine()
            storageEngineWithIndex = StorageEngine(storageAdapter: storageAdapterWithIndex,
                                                   dataStoreConfiguration: .default,
                                                   syncEngine: syncEngineWithIndex,
                                                   validAPIPluginKey: validAPIPluginKey,
                                                   validAuthPluginKey: validAuthPluginKey)

            ModelRegistry.register(modelType: CustomerSecondaryIndexV2.self)
            ModelRegistry.register(modelType: CustomerMultipleSecondaryIndexV2.self)

            do {
                try storageEngine.setUp(modelSchemas: [CustomerSecondaryIndexV2.schema])
                try storageEngine.setUp(modelSchemas: [CustomerMultipleSecondaryIndexV2.schema])

                try storageEngineWithIndex.setUp(modelSchemas: [CustomerSecondaryIndexV2.schema])
                try storageEngineWithIndex.setUp(modelSchemas: [CustomerMultipleSecondaryIndexV2.schema])
            } catch {
                XCTFail("Failed to setup storage engine")
            }
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    //  `CustomerSecondaryIndexV2` Model Schema contains a secondary index, namely,
    //  byRepresentative - where `accountRepresentativeID` is hashkey
    //  In this test, query is done w.r.t. to secondary index `byRepresentative` where
    //  the predicate checks for equality with `accountRepresentativeID`

    //  For brevity, two tables (one with SQLite indexing for secondary indexes in schema and one without SQLite
    //  indexes) is created with many records(>=1000) where each customer has a single
    //  letter name (for e.g. "a", "b"), phonenumber is a string of length 10 having small letters,
    //  and accountRepresentativeID is a string of length 10 having capital letters

    //  % decrease in query time is printed to the console
    //  Results are noted when run on Intel Core i7, 2.6Ghz, 6 Core
    //  16GB 2667 MHz DDR4 Memory (inMemory, empirical observations)
    //  Number of records   -   % decrease in query time
    //  100                 -   7.7
    //  1000                -   12.63
    //  5000                -   40.2
    //  10000 (5 iterations)-   54.85
    func testQueryPerformanceForModelWithSingleIndex() {
        var averageTimeForQuery1: Double = 0.0
        var averageTimeForQuery2: Double = 0.0

        for _ in 0 ... iterations {
            setUpStorageEngine()
            for _ in 0 ... numberOfRecords {
                let customer = CustomerSecondaryIndexV2(
                    name: randomSmallCharacterString(length: 1),
                    phoneNumber: randomNumericString(length: 10),
                    accountRepresentativeID: randomCapitalCharacterString(length: 10),
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now())

                guard case .success = saveModelSynchronous(model: customer, storageEngine: storageEngine),
                    case .success = saveModelSynchronous(model: customer, storageEngine: storageEngineWithIndex) else {
                        XCTFail("Failed to save customer \(customer)")
                        return
                }
            }

            // Create a unique customer so that query has atleast one successful search result
            let name = "j"
            let phoneNumber = "1234567890"
            let accountRepresentativeID = "ABCDEFGHIJ"
            let uniqueCustomer = CustomerSecondaryIndexV2(
                name: name,
                phoneNumber: phoneNumber,
                accountRepresentativeID: accountRepresentativeID,
                createdAt: Temporal.DateTime.now(),
                updatedAt: Temporal.DateTime.now())

            guard case .success = saveModelSynchronous(model: uniqueCustomer, storageEngine: storageEngine),
                case .success = saveModelSynchronous(model: uniqueCustomer, storageEngine: storageEngineWithIndex)
            else {
                    XCTFail("Failed to save customer \(uniqueCustomer)")
                    return
            }

            // Measure time needed to run a query
            let predicate =
            CustomerSecondaryIndexV2.keys.accountRepresentativeID.eq(accountRepresentativeID)

            let startTimeQuery1 = CACurrentMediaTime()
            guard case .success =
                    queryModelSynchronous(modelType: CustomerSecondaryIndexV2.self,
                                          predicate: predicate,
                                          storageEngine: storageEngine) else {
                    XCTFail("Failed to query customer")
                    return
            }
            let timeElapsedQuery1 = CACurrentMediaTime() - startTimeQuery1
            averageTimeForQuery1 += timeElapsedQuery1

            let startTimeQuery2 = CACurrentMediaTime()
            guard case .success =
                    queryModelSynchronous(modelType: CustomerSecondaryIndexV2.self,
                                          predicate: predicate,
                                          storageEngine: storageEngineWithIndex) else {
                    XCTFail("Failed to query customer")
                    return
            }
            let timeElapsedQuery2 = CACurrentMediaTime() - startTimeQuery2
            averageTimeForQuery2 += timeElapsedQuery2
        }

        averageTimeForQuery1 = (averageTimeForQuery1 / Double(iterations))
        averageTimeForQuery2 = (averageTimeForQuery2 / Double(iterations))
        print("Average time elapsed for query 1 (without SQLite indexing) : \(averageTimeForQuery1) s.")
        print("Average time time query 2 (with SQLite indexing) : \(averageTimeForQuery2) s.")

        let percentDecreaseInQueryTime =
        (averageTimeForQuery1 - averageTimeForQuery2) * Double(100) / averageTimeForQuery1
        print("% decrease in query time: \(percentDecreaseInQueryTime)")
    }

    //  `CustomerMultipleSecondaryIndexV2` Model Schema contains two secondary indexes, namely,
    //  byNameAndPhoneNumber - where name is hashkey and phoneNumber is sortkey
    //  byAgeAndPhoneNumber - where age is hashkey and phoneNumber is sortkey
    //  In this test, query is done w.r.t. to secondary index `byNameAndPhoneNumber` where
    //  the predicate checks for equality with `name` and `phoneNumber` which begins with "1"

    //  For brevity, two tables (one with SQLite indexing for secondary indexes in schema and one without SQLite
    //  indexes) is created with many records(>=1000) where each customer has a single
    //  letter name (for e.g. "a", "b"), phonenumber is a string of length 10 having small letters, age between 1-100,
    //  and accountRepresentativeID is a string of length 10 having capital letters

    //  % decrease in query time is printed to the console
    //  Results are noted when run on Intel Core i7, 2.6Ghz, 6 Core
    //  16GB 2667 MHz DDR4 Memory (inMemory, empirical observations)
    //  Number of records   -   % decrease in query time
    //  100                 -   0.15
    //  1000                -   4.69
    //  5000                -   5.84
    //  10000               -   11.56
    func testQueryPerformanceForModelWithMultipleIndexes1() {
        var averageTimeForQuery1: Double = 0.0
        var averageTimeForQuery2: Double = 0.0

        for _ in 0 ... iterations {
            setUpStorageEngine()
            for _ in 0 ... numberOfRecords {
                let customer = CustomerMultipleSecondaryIndexV2(
                    name: randomSmallCharacterString(length: 1),
                    phoneNumber: randomNumericString(length: 10),
                    age: Int.random(in: 1 ..< 100),
                    accountRepresentativeID: randomCapitalCharacterString(length: 10),
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now())

                guard case .success = saveModelSynchronous(model: customer, storageEngine: storageEngine),
                    case .success = saveModelSynchronous(model: customer, storageEngine: storageEngineWithIndex) else {
                        XCTFail("Failed to save customer \(customer)")
                        return
                }
            }

            // Create a unique customer so that query has atleast one successful search result
            let name = "j"
            let phoneNumber = "1234567890"
            let accountRepresentativeID = "ABCDEFGHIJ"
            let uniqueCustomer = CustomerMultipleSecondaryIndexV2(
                name: name,
                phoneNumber: phoneNumber,
                age: 30,
                accountRepresentativeID: accountRepresentativeID,
                createdAt: Temporal.DateTime.now(),
                updatedAt: Temporal.DateTime.now())

            guard case .success = saveModelSynchronous(model: uniqueCustomer, storageEngine: storageEngine),
                case .success = saveModelSynchronous(model: uniqueCustomer, storageEngine: storageEngineWithIndex)
            else {
                    XCTFail("Failed to save customer \(uniqueCustomer)")
                    return
            }

            // Measure time needed to run a query
            let predicate =
            CustomerMultipleSecondaryIndexV2.keys.name.eq(name) &&
            CustomerMultipleSecondaryIndexV2.keys.phoneNumber.beginsWith("1")

            let startTimeQuery1 = CACurrentMediaTime()
            guard case .success =
                    queryModelSynchronous(modelType: CustomerMultipleSecondaryIndexV2.self,
                                          predicate: predicate,
                                          storageEngine: storageEngine) else {
                    XCTFail("Failed to query customer")
                    return
            }
            let timeElapsedQuery1 = CACurrentMediaTime() - startTimeQuery1
            averageTimeForQuery1 += timeElapsedQuery1

            let startTimeQuery2 = CACurrentMediaTime()
            guard case .success =
                    queryModelSynchronous(modelType: CustomerMultipleSecondaryIndexV2.self,
                                          predicate: predicate,
                                          storageEngine: storageEngineWithIndex) else {
                    XCTFail("Failed to query customer")
                    return
            }
            let timeElapsedQuery2 = CACurrentMediaTime() - startTimeQuery2
            averageTimeForQuery2 += timeElapsedQuery2
        }

        averageTimeForQuery1 = (averageTimeForQuery1 / Double(iterations))
        averageTimeForQuery2 = (averageTimeForQuery2 / Double(iterations))
        print("Average time elapsed for query 1 (without SQLite indexing) : \(averageTimeForQuery1) s.")
        print("Average time time query 2 (with SQLite indexing) : \(averageTimeForQuery2) s.")

        let percentDecreaseInQueryTime =
        (averageTimeForQuery1 - averageTimeForQuery2) * Double(100) / averageTimeForQuery1
        print("% decrease in query time: \(percentDecreaseInQueryTime)")
    }

    //  `CustomerMultipleSecondaryIndexV2` Model Schema contains two secondary indexes, namely,
    //  byNameAndPhoneNumber - where name is hashkey and phoneNumber is sortkey
    //  byAgeAndPhoneNumber - where age is hashkey and phoneNumber is sortkey
    //  In this test, query is done w.r.t. to secondary index `byAgeAndPhoneNumber` where
    //  the predicate checks for equality with `age` and `phoneNumber` which begins with "1"

    //  For brevity, two tables (one with SQLite indexing for secondary indexes in schema and one without SQLite
    //  indexes) is created with many records(>=1000) where each customer has a single
    //  letter name (for e.g. "a", "b"), phonenumber is a string of length 10 having small letters, age between 1-100,
    //  and accountRepresentativeID is a string of length 10 having capital letters

    //  % decrease in query time is printed to the console
    //  Results are noted when run on Intel Core i7, 2.6Ghz, 6 Core
    //  16GB 2667 MHz DDR4 Memory (inMemory, empirical observations)
    //  Number of records   -   % decrease in query time
    //  100                 -   1.53
    //  1000                -   2.63
    //  5000                -   5.4
    //  10000 (5 iterations)-   6.51
    func testQueryPerformanceForModelWithMultipleIndexes2() {
        var averageTimeForQuery1: Double = 0.0
        var averageTimeForQuery2: Double = 0.0

        for _ in 0 ... iterations {
            setUpStorageEngine()
            for _ in 0 ... numberOfRecords {
                let customer = CustomerMultipleSecondaryIndexV2(
                    name: randomSmallCharacterString(length: 1),
                    phoneNumber: randomNumericString(length: 10),
                    age: Int.random(in: 1 ..< 100),
                    accountRepresentativeID: randomCapitalCharacterString(length: 10),
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now())

                guard case .success = saveModelSynchronous(model: customer, storageEngine: storageEngine),
                    case .success = saveModelSynchronous(model: customer, storageEngine: storageEngineWithIndex) else {
                        XCTFail("Failed to save customer \(customer)")
                        return
                }
            }

            // Create a unique customer so that query has atleast one successful search result
            let name = "j"
            let phoneNumber = "1234567890"
            let accountRepresentativeID = "ABCDEFGHIJ"
            let age = 30
            let uniqueCustomer = CustomerMultipleSecondaryIndexV2(
                name: name,
                phoneNumber: phoneNumber,
                age: age,
                accountRepresentativeID: accountRepresentativeID,
                createdAt: Temporal.DateTime.now(),
                updatedAt: Temporal.DateTime.now())

            guard case .success = saveModelSynchronous(model: uniqueCustomer, storageEngine: storageEngine),
                  case .success = saveModelSynchronous(model: uniqueCustomer, storageEngine: storageEngineWithIndex)
            else {
                XCTFail("Failed to save customer \(uniqueCustomer)")
                return
            }

            // Measure time needed to run a query
            let predicate =
            CustomerMultipleSecondaryIndexV2.keys.age.eq(age) &&
            CustomerMultipleSecondaryIndexV2.keys.phoneNumber.beginsWith("1")

            let startTimeQuery1 = CACurrentMediaTime()
            guard case .success =
                    queryModelSynchronous(modelType: CustomerMultipleSecondaryIndexV2.self,
                                          predicate: predicate,
                                          storageEngine: storageEngine) else {
                    XCTFail("Failed to query customer")
                    return
            }
            let timeElapsedQuery1 = CACurrentMediaTime() - startTimeQuery1
            averageTimeForQuery1 += timeElapsedQuery1

            let startTimeQuery2 = CACurrentMediaTime()
            guard case .success =
                    queryModelSynchronous(modelType: CustomerMultipleSecondaryIndexV2.self,
                                          predicate: predicate,
                                          storageEngine: storageEngineWithIndex) else {
                    XCTFail("Failed to query customer")
                    return
            }
            let timeElapsedQuery2 = CACurrentMediaTime() - startTimeQuery2
            averageTimeForQuery2 += timeElapsedQuery2
        }

        averageTimeForQuery1 = (averageTimeForQuery1 / Double(iterations))
        averageTimeForQuery2 = (averageTimeForQuery2 / Double(iterations))
        print("Average time elapsed for query 1 (without SQLite indexing) : \(averageTimeForQuery1) s.")
        print("Average time time query 2 (with SQLite indexing) : \(averageTimeForQuery2) s.")

        let percentDecreaseInQueryTime =
        (averageTimeForQuery1 - averageTimeForQuery2) * Double(100) / averageTimeForQuery1
        print("% decrease in query time: \(percentDecreaseInQueryTime)")
    }

    func randomSmallCharacterString(length: Int) -> String {
         let smallLetters = "abcdefghijklmnopqrstuvwxyz"
         var string = ""
         for _ in 0 ..< length {
             string.append(smallLetters.randomElement()!)
         }
         return string
    }

    func randomCapitalCharacterString(length: Int) -> String {
         let capitalLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
         var string = ""
         for _ in 0 ..< length {
             string.append(capitalLetters.randomElement()!)
         }
         return string
    }

    func randomNumericString(length: Int) -> String {
         let numbers = "0123456789"
         var string = ""
         for _ in 0 ..< length {
             string.append(numbers.randomElement()!)
         }
         return string
    }

    func saveModelSynchronous<M: Model>(model: M, storageEngine: StorageEngine) -> DataStoreResult<M> {
        let saveFinished = expectation(description: "Save finished")
        var result: DataStoreResult<M>?

        storageEngine.save(model) { sResult in
            result = sResult
            saveFinished.fulfill()
        }
        wait(for: [saveFinished], timeout: defaultTimeout)
        guard let saveResult = result else {
            return .failure(causedBy: "Save operation timed out")
        }
        return saveResult
    }

    func querySingleModelSynchronous<M: Model>(modelType: M.Type,
                                               predicate: QueryPredicate,
                                               storageEngine: StorageEngine) -> DataStoreResult<M> {
        let result = queryModelSynchronous(modelType: modelType, predicate: predicate, storageEngine: storageEngine)

        switch result {
        case .success(let models):
            if models.isEmpty {
                return .failure(causedBy: "Found no models, of type \(modelType.modelName)")
            } else if models.count > 1 {
                return .failure(causedBy: "Found more than one model of type \(modelType.modelName)")
            } else {
                return .success(models.first!)
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    func queryModelSynchronous<M: Model>(modelType: M.Type,
                                         predicate: QueryPredicate,
                                         storageEngine: StorageEngine) -> DataStoreResult<[M]> {
        let queryFinished = expectation(description: "Query Finished")
        var result: DataStoreResult<[M]>?

        storageEngine.query(modelType, predicate: predicate) { qResult in
            result = qResult
            queryFinished.fulfill()
        }

        wait(for: [queryFinished], timeout: defaultTimeout)
        guard let queryResult = result else {
            return .failure(causedBy: "Query operation timed out")
        }
        return queryResult
    }
}
