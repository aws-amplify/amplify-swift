//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol QueryTranslator {

    associatedtype Value

    func translateToDelete(from model: Model) -> Query<Value>

    func translateToInsert(from model: Model) -> Query<Value>

    func translateToQuery(from modelType: Model.Type,
                          condition: QueryCondition?) -> Query<Value>

    func translateToUpdate(from model: Model) -> Query<Value>

}
