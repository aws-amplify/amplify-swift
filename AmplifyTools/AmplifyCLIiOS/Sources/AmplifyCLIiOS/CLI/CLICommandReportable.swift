//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol CLICommandReportable {
    func report(result: AmplifyCommandResult)
}

extension CLICommandReportable {
    private func reportCommandSuccess(for tasks: [AmplifyCommandTaskResult]) {
        for task in tasks {
            switch task {
            case .success(let message):
                print("-- ✅ \(message)")
            case .failure(let error):
                print("-- 🚫 \(error)")
            }
        }
    }

    private func reportCommandFailure(_ error: AmplifyCommandError) {
        print(error.debugDescription)
    }

    func report(result: AmplifyCommandResult) {
        switch result {
        case .success(let intermediateRes):
            reportCommandSuccess(for: intermediateRes)

        case .failure(let error):
            reportCommandFailure(error)
        }
    }
}
