//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSPluginsCore
import AWSClientRuntime

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

    func testClaimsWithSpecialCharacters() throws {
        let tokenString = """
                eyJraWQiOiJaS0s5ZUlZbmo4UEtGQzUrMHdMQUhJMjd0SWcxRkRRZU9ybW82SVwvdFkwbz0iLCJhbGciOiJSUzI1NiJ9\
                .eyJmYy1pZCI6IjE2ZjFkOTM3LTY5YmQtNGI2OS1hMzJmLWYwNjkxNGY0YzIxOCIsInN1YiI6IjE2ZjFkOTM3LTY5YmQ\
                tNGI2OS1hMzJmLWYwNjkxNGY0YzIxOCIsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9\
                uYXdzLmNvbVwvdXMtZWFzdC0xXzhqRVI4cHY0ViIsImNvZ25pdG86dXNlcm5hbWUiOiIxNmYxZDkzNy02OWJkLTRiNjk\
                tYTMyZi1mMDY5MTRmNGMyMTgiLCJnaXZlbl9uYW1lIjoiQm_DsWEiLCJhdWQiOiI2bTZ1dWlocmhzM3BzbGI0amhhdHJ\
                zYnBxYyIsImV2ZW50X2lkIjoiYjAzZjQ1YWMtM2FlMS0xMWU5LTlkZDItODcyODBlYTRiMGNhIiwidG9rZW5fdXNlIjo\
                iaWQiLCJhdXRoX3RpbWUiOjE1NTEzMDc2NjEsImV4cCI6MTU1MTMxMTI2MSwiaWF0IjoxNTUxMzA3NjYxLCJmYW1pbHl\
                fbmFtZSI6IkJhcsOnYSIsImVtYWlsIjoiaW5mb0Bkb25hYmFyY2EzLmRlIn0.OGT9siqf_tAYrhVA-EhYabz-L4ZNLe0\
                w0N7fH4rASs0scRGm-34g96qmSZoD1j74bplIRcMqoFaDI0cLejyeeLN-z2ib1MDsuMnyq8cHfuu4x4qBGVcxWGkIOBj\
                AEdsiU5U4xsEuaRpgC1rNiS7X6t0vQsDj3Jw3cV1XmJbeHaZB8D7EUMW6-zk4ZT2jKrpiaeaPTFoJJFOYiYdlJj4zkxX\
                T2nzldS9K57Mwz91YgbjF_VCxPl84b-aiBoj7_ARdu8LDP2HHkpVoNslWYuusatBOOJvTT56Fa2kJzZqoUuAnGiC8AYU\
                _YKpL_iu-wv5xnWHthuDCxhpl85cdROrAbA
                """

        let claimsResult = awsAuthService.getTokenClaims(tokenString: tokenString)
        XCTAssertNotNil(claimsResult)
        guard case .success(let claims) = claimsResult else {
            XCTFail("Unable to parse claims")
            return
        }

        guard let givenName = claims["given_name"] as? String else {
            XCTFail("Claim should contain name")
            return
        }
        XCTAssertEqual(givenName, "Boña")

        guard let familyName = claims["family_name"] as? String else {
            XCTFail("Claim should contain sub")
            return
        }
        XCTAssertEqual(familyName, "Barça")

        guard let iat = claims["iat"] as? Int else {
            XCTFail("Claim should contain iat")
            return
        }

        guard let sub = claims["sub"] as? String else {
            XCTFail("Claim should contain sub")
            return
        }
        XCTAssertEqual(sub, "16f1d937-69bd-4b69-a32f-f06914f4c218")

        XCTAssertEqual(iat, 1_551_307_661)
    }


    /// Given: A credentials that will expire after 100 second
    /// When: I convert the credentials to AWS SDK ClientRuntime
    /// Then: I should get a valid CRT credentials
    func testValidCredentialsToCRTConversion() throws {

        let credentials = MockCredentials(
            sessionToken: "somesession",
            accessKeyId: "accessKeyId",
            secretAccessKey: "secretAccessKey",
            expiration: Date().addingTimeInterval(100))
        let sdkCredentials = credentials.toAWSSDKCredentials()
        XCTAssertNotNil(sdkCredentials)
    }

    /// Given: A credentials that expired 100 second back
    /// When: I convert the credentials to AWS SDK ClientRuntime
    /// Then: I should get a valid CRT credentials
    func testExpiredCredentialsToCRTConversion() throws {

        let credentials = MockCredentials(
            sessionToken: "somesession",
            accessKeyId: "accessKeyId",
            secretAccessKey: "secretAccessKey",
            expiration: Date().addingTimeInterval(-100))
        let sdkCredentials = credentials.toAWSSDKCredentials()
        XCTAssertNotNil(sdkCredentials)
    }
}


struct MockCredentials: AWSTemporaryCredentials {
    let sessionToken: String
    let accessKeyId: String
    let secretAccessKey: String
    let expiration: Date
}
