//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import XCTest

@testable import Amplify
@testable import AWSPluginsCore

class AWSAuthServiceTests: XCTestCase {

    var awsAuthService: AWSAuthServiceBehavior!

    override func setUp() {
        awsAuthService = AWSAuthService()
    }
    func testValidTokenGetTokenClaims() throws {
        let tokenString = """
        eyJraWQiOiI1U3FZLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tb1pNVy0tLUhRPSIsImFsZyI6IlJTMjU2In0=.\
        eyJzdWIiOiJkZWFkYmVlZi1mZmZmLWZmZmYtZmZmZi1mNjJkZGVhZGJlZWYiLCJldmVudF9pZCI6ImJlZWZkZWFkLWZmZmYtZmZm\
        Zi1hYWFhLWFhYWFiYmJiY2NjYyIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiYXdzLmNvZ25pdG8uc2lnbmluLnVzZXIuY\
        WRtaW4iLCJhdXRoX3RpbWUiOjE2MDAwMDAwMDAsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy13ZXN0LTIuYW1hem9uYX\
        dzLmNvbVwvdXMtd2VzdC0yX2FhYWFiYmJiYSIsImV4cCI6MTYwMDAwMDAwMCwiaWF0IjoxNjAyMjcwMDAwLCJqdGkiOiJjY2NjZGR\
        kZC1lZWVlLWZmZmYtYWFhYS1iYmJiY2NjY2RkZGQiLCJjbGllbnRfaWQiOiI2ZmZmZmVlZWVkZGRkY2NjY2JiYmJhYWFhIiwidXNl\
        cm5hbWUiOiJ0ZXN0dXNlciJ9.\
        pzzpzzzzzpzppzppzzpzzzpzzzzzzzpz-zpzzppz_zzzppzp---pppp-p-ppp-zz-ppzzpzzzzzzzzppzpp--zpzzp-zz-pppz-pz\
        -zzpzz-zp_-pppzpzzzp--zzpzpzppp--zpz-zppzpppppzpzzpzp-p-zz-z--zzpzzzzzpp-p-zp-z_p-pzpzzppppzzzzzpzzzp\
        pz-zpppzpp-zzpzz-zppppz-pzpzppzzppzpzp--pz-zzzzpzzpzpp-zpzzzpz-pz--zpzzz-ppzpppppzz--ppzppzppppzp-zpp\
        pppppzz-zzpppzpp-pzzzzppp-pzzpzpzpzzppz
        """
        let claimsResult = awsAuthService.getTokenClaims(tokenString: tokenString)
        guard case .success(let claims) = claimsResult else {
            XCTFail("Unable to parse claims")
            return
        }
        guard let sub = claims["sub"] as? String else {
            XCTFail("unable to get sub from jwt token")
            return
        }
        guard let username = claims["username"] as? String else {
            XCTFail("unable to get username from jwt token")
            return
        }
        XCTAssert(sub == "deadbeef-ffff-ffff-ffff-f62ddeadbeef")
        XCTAssert(username == "testuser")
    }

    func testTwoPiecesTokenGetTokenClaims() throws {
        let tokenString = """
        eyJraWQiOiI1U3FZLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tb1pNVy0tLUhRPSIsImFsZyI6IlJTMjU2In0=\
        eyJzdWIiOiJkZWFkYmVlZi1mZmZmLWZmZmYtZmZmZi1mNjJkZGVhZGJlZWYiLCJldmVudF9pZCI6ImJlZWZkZWFkLWZmZmYtZmZm\
        Zi1hYWFhLWFhYWFiYmJiY2NjYyIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiYXdzLmNvZ25pdG8uc2lnbmluLnVzZXIuY\
        WRtaW4iLCJhdXRoX3RpbWUiOjE2MDAwMDAwMDAsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy13ZXN0LTIuYW1hem9uYX\
        dzLmNvbVwvdXMtd2VzdC0yX2FhYWFiYmJiYSIsImV4cCI6MTYwMDAwMDAwMCwiaWF0IjoxNjAyMjcwMDAwLCJqdGkiOiJjY2NjZGR\
        kZC1lZWVlLWZmZmYtYWFhYS1iYmJiY2NjY2RkZGQiLCJjbGllbnRfaWQiOiI2ZmZmZmVlZWVkZGRkY2NjY2JiYmJhYWFhIiwidXNl\
        cm5hbWUiOiJ0ZXN0dXNlciJ9.\
        pzzpzzzzzpzppzppzzpzzzpzzzzzzzpz-zpzzppz_zzzppzp---pppp-p-ppp-zz-ppzzpzzzzzzzzppzpp--zpzzp-zz-pppz-pz\
        -zzpzz-zp_-pppzpzzzp--zzpzpzppp--zpz-zppzpppppzpzzpzp-p-zz-z--zzpzzzzzpp-p-zp-z_p-pzpzzppppzzzzzpzzzp\
        pz-zpppzpp-zzpzz-zppppz-pzpzppzzppzpzp--pz-zzzzpzzpzpp-zpzzzpz-pz--zpzzz-ppzpppppzz--ppzppzppppzp-zpp\
        pppppzz-zzpppzpp-pzzzzppp-pzzpzpzpzzppz
        """
        let claimsResult = awsAuthService.getTokenClaims(tokenString: tokenString)

        guard case .failure(let error) = claimsResult else {
            XCTFail("passed in token with two parts, but expecting 3")
            return
        }
        guard case .validation = error else {
            XCTFail("expecting validation error")
            return
        }
    }

    func testInvalidJsonTokenGetTokenClaims() throws {
        let tokenString = """
        eyJraWQiOiI1U3FZLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tb1pNVy0tLUhRPSIsImFsZyI6IlJTMjU2In0=.\
        InN1YiI6ImRlYWRiZWVmLWZmZmYtZmZmZi1mZmZmLWY2MmRkZWFkYmVlZiIsImV2ZW50X2lkIjoiYmVlZmRlYWQtZmZmZi1mZmZmL\
        WFhYWEtYWFhYWJiYmJjY2NjIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJhd3MuY29nbml0by5zaWduaW4udXNlci5hZG\
        1pbiIsImF1dGhfdGltZSI6MTYwMDAwMDAwMCwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3M\
        uY29tXC91cy13ZXN0LTJfYWFhYWJiYmJhIiwiZXhwIjoxNjAwMDAwMDAwLCJpYXQiOjE2MDIyNzAwMDAsImp0aSI6ImNjY2NkZGRk\
        LWVlZWUtZmZmZi1hYWFhLWJiYmJjY2NjZGRkZCIsImNsaWVudF9pZCI6IjZmZmZmZWVlZWRkZGRjY2NjYmJiYmFhYWEiLCJ1c2Vyb\
        mFtZSI6InRlc3R1c2VyIn0=.\
        pzzpzzzzzpzppzppzzpzzzpzzzzzzzpz-zpzzppz_zzzppzp---pppp-p-ppp-zz-ppzzpzzzzzzzzppzpp--zpzzp-zz-pppz-pz\
        -zzpzz-zp_-pppzpzzzp--zzpzpzppp--zpz-zppzpppppzpzzpzp-p-zz-z--zzpzzzzzpp-p-zp-z_p-pzpzzppppzzzzzpzzzp\
        pz-zpppzpp-zzpzz-zppppz-pzpzppzzppzpzp--pz-zzzzpzzpzpp-zpzzzpz-pz--zpzzz-ppzpppppzz--ppzppzppppzp-zpp\
        pppppzz-zzpppzpp-pzzzzppp-pzzpzpzpzzppz
        """
        let claimsResult = awsAuthService.getTokenClaims(tokenString: tokenString)

        guard case .failure(let authError) = claimsResult else {
            XCTFail("passed in token with two parts, but expecting 3")
            return
        }
        guard case .validation(_, _, _, let error) = authError else {
            XCTFail("expecting validation error")
            return
        }
        guard let jsonDecodeError = error as NSError? else {
            XCTFail("expecting json decode error")
            return
        }
        XCTAssertEqual(jsonDecodeError.code, 3_840)
    }
}
