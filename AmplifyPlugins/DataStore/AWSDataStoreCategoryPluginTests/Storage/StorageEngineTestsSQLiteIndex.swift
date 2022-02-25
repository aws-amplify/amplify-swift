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
@testable import AWSDataStorePlugin

// swiftlint:disable type_body_length
class StorageEngineTestsSQLiteIndex: StorageEngineTestsBase {

    // number of records to be created
    let numberOfRecords = 1_000

    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .warn
    }

    func setupStorageEngine() {
        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)
            syncEngine = MockRemoteSyncEngine()
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)

            ModelRegistry.register(modelType: CustomerSecondaryIndexV2.self)
            ModelRegistry.register(modelType: CustomerMultipleSecondaryIndexV2.self)

            do {
                try storageEngine.setUp(modelSchemas: [CustomerSecondaryIndexV2.schema])
                try storageEngine.setUp(modelSchemas: [CustomerMultipleSecondaryIndexV2.schema])
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

    //  For brevity, a table (with SQLite indexing for secondary indexes in schema)
    //  is created with many records(100 to 10000) where each customer has a single
    //  letter name (for e.g. "a", "b"), phonenumber is a string of length 10 having numbers,
    //  and accountRepresentativeID is a string of length 10 having capital letters

    //  Results are noted when run on Intel Core i7, 2.6Ghz, 6 Core
    //  16GB 2667 MHz DDR4 Memory (inMemory, empirical observations)
    //  with SQLite indexes created vs not created
    //  Number of records   -   Avg. query time with    -   Previous (s)
    //                          indexes (s)
    //  100                 -   0.0028375326990499163   -   0.0030892116992617957
    //  1000                -   0.002908085302624386    -   0.0032255952028208412
    //  5000                -   0.0032134409993886948   -   0.00478174310119357
    //  10000               -   0.0033998960039345548   -   0.006051322101324331
    func testQueryPerformanceForModelWithSingleIndex() {
        var averageTimeForQuery: Double = 0.0
        var iterations = 0
        measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            iterations += 1
            setupStorageEngine()
            for _ in 0 ... numberOfRecords {
                let customer = CustomerSecondaryIndexV2(
                    name: randomSmallCharacterString(length: 1),
                    phoneNumber: randomNumericString(length: 10),
                    accountRepresentativeID: randomCapitalCharacterString(length: 10),
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now())

                guard case .success = saveModelSynchronous(model: customer, storageEngine: storageEngine) else {
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

            guard case .success = saveModelSynchronous(model: uniqueCustomer, storageEngine: storageEngine) else {
                XCTFail("Failed to save customer \(uniqueCustomer)")
                return
            }

            let predicate = CustomerSecondaryIndexV2.keys.accountRepresentativeID.eq(accountRepresentativeID)

            let startTimeQuery1 = CACurrentMediaTime()
            startMeasuring()
            guard case .success = queryModelSynchronous(modelType: CustomerSecondaryIndexV2.self,
                                                        predicate: predicate,
                                                        storageEngine: storageEngine) else {
                XCTFail("Failed to query customer")
                return
            }
            stopMeasuring()
            let timeElapsedQuery1 = CACurrentMediaTime() - startTimeQuery1
            averageTimeForQuery += timeElapsedQuery1
            print("Query time \(#function) number of records \(numberOfRecords) : \(timeElapsedQuery1)")
        }
        averageTimeForQuery /= Double(iterations)
        print("Average query time \(#function) number of records \(numberOfRecords) : \(averageTimeForQuery)")
    }

    //  `CustomerMultipleSecondaryIndexV2` Model Schema contains two secondary indexes, namely,
    //  byNameAndPhoneNumber - where name is hashkey and phoneNumber is sortkey
    //  byAgeAndPhoneNumber - where age is hashkey and phoneNumber is sortkey
    //  In this test, query is done w.r.t. to secondary index `byNameAndPhoneNumber` where
    //  the predicate checks for equality with `name` and `phoneNumber` which begins with "1"

    //  For brevity, a table (with SQLite indexing for secondary indexes in schema)
    //  is created with many records(100 to 10000) where each customer has a single
    //  letter name (for e.g. "a", "b"), phonenumber is a string of length 10 having numbers, age between 1-100,
    //  and accountRepresentativeID is a string of length 10 having capital letters

    //  Results are noted when run on Intel Core i7, 2.6Ghz, 6 Core
    //  16GB 2667 MHz DDR4 Memory (inMemory, empirical observations)
    //  with SQLite indexes created vs not created
    //  Number of records   -   Avg. query time with    -   Previous (s)
    //                          indexes (s)
    //  100                 -   0.0031190951005555688   -   0.0036742549025802875
    //  1000                -   0.010179293301189319    -   0.011310623202007264
    //  5000                -   0.03966123380087083     -   0.04700456840073457
    //  10000               -   0.08497165249864339     -   0.09597435819596285
    func testQueryPerformanceForModelWithMultipleIndexes1() {
        var averageTimeForQuery: Double = 0.0
        var iterations = 0
        measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            iterations += 1
            setupStorageEngine()
            for _ in 0 ... numberOfRecords {
                let customer = CustomerMultipleSecondaryIndexV2(
                    name: randomSmallCharacterString(length: 1),
                    phoneNumber: randomNumericString(length: 10),
                    age: Int.random(in: 1 ..< 100),
                    accountRepresentativeID: randomCapitalCharacterString(length: 10),
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now())

                guard case .success = saveModelSynchronous(model: customer, storageEngine: storageEngine) else {
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

            guard case .success = saveModelSynchronous(model: uniqueCustomer, storageEngine: storageEngine) else {
                XCTFail("Failed to save customer \(uniqueCustomer)")
                return
            }

            let predicate = CustomerMultipleSecondaryIndexV2.keys.name.eq(name) &&
            CustomerMultipleSecondaryIndexV2.keys.phoneNumber.beginsWith("1")

            let startTimeQuery1 = CACurrentMediaTime()
            startMeasuring()
            guard case .success = queryModelSynchronous(modelType: CustomerMultipleSecondaryIndexV2.self,
                                                        predicate: predicate,
                                                        storageEngine: storageEngine) else {
                XCTFail("Failed to query customer")
                return
            }
            stopMeasuring()
            let timeElapsedQuery1 = CACurrentMediaTime() - startTimeQuery1
            averageTimeForQuery += timeElapsedQuery1
            print("Query time \(#function) number of records \(numberOfRecords) : \(timeElapsedQuery1)")
        }
        averageTimeForQuery /= Double(iterations)
        print("Average query time \(#function) number of records \(numberOfRecords) : \(averageTimeForQuery)")
    }

    //  `CustomerMultipleSecondaryIndexV2` Model Schema contains two secondary indexes, namely,
    //  byNameAndPhoneNumber - where name is hashkey and phoneNumber is sortkey
    //  byAgeAndPhoneNumber - where age is hashkey and phoneNumber is sortkey
    //  In this test, query is done w.r.t. to secondary index `byAgeAndPhoneNumber` where
    //  the predicate checks for equality with `age` and `phoneNumber` which begins with "1"

    //  For brevity, a table (with SQLite indexing for secondary indexes in schema)
    //  is created with many records(100 to 10000) where each customer has a single
    //  letter name (for e.g. "a", "b"), phonenumber is a string of length 10 having numbers, age between 1-100,
    //  and accountRepresentativeID is a string of length 10 having capital letters

    //  Results are noted when run on Intel Core i7, 2.6Ghz, 6 Core
    //  16GB 2667 MHz DDR4 Memory (inMemory, empirical observations)
    //  with SQLite indexes created vs not created
    //  Number of records   -   Avg. query time with    -   Previous (s)
    //                          indexes (s)
    //  100                 -   0.003238815201621037    -   0.003389103499648627
    //  1000                -   0.004494062899902928    -   0.004931295602000318
    //  5000                -   0.011302956998406444    -   0.013200746997934766
    //  10000               -   0.02146193390071858     -   0.025970560003770515
    func testQueryPerformanceForModelWithMultipleIndexes2() {
        var averageTimeForQuery: Double = 0.0
        var iterations = 0
        measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            iterations += 1
            setupStorageEngine()
            for _ in 0 ... numberOfRecords {
                let customer = CustomerMultipleSecondaryIndexV2(
                    name: randomSmallCharacterString(length: 1),
                    phoneNumber: randomNumericString(length: 10),
                    age: Int.random(in: 1 ..< 100),
                    accountRepresentativeID: randomCapitalCharacterString(length: 10),
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now())

                guard case .success = saveModelSynchronous(model: customer, storageEngine: storageEngine) else {
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

            guard case .success = saveModelSynchronous(model: uniqueCustomer, storageEngine: storageEngine) else {
                XCTFail("Failed to save customer \(uniqueCustomer)")
                return
            }

            let predicate =
            CustomerMultipleSecondaryIndexV2.keys.age.eq(age) &&
            CustomerMultipleSecondaryIndexV2.keys.phoneNumber.beginsWith("1")

            let startTimeQuery1 = CACurrentMediaTime()
            startMeasuring()
            guard case .success =
                    queryModelSynchronous(modelType: CustomerMultipleSecondaryIndexV2.self,
                                          predicate: predicate,
                                          storageEngine: storageEngine) else {
                    XCTFail("Failed to query customer")
                    return
            }
            stopMeasuring()
            let timeElapsedQuery1 = CACurrentMediaTime() - startTimeQuery1
            averageTimeForQuery += timeElapsedQuery1
            print("Query time \(#function) number of records \(numberOfRecords) : \(timeElapsedQuery1)")
        }
        averageTimeForQuery /= Double(iterations)
        print("Average query time \(#function) number of records \(numberOfRecords) : \(averageTimeForQuery)")
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
