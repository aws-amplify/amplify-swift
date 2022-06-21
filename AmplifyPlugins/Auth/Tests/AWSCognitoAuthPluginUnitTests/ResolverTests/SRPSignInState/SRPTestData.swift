//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

// MARK: - Test Data

extension SRPStateData {
    static let testData = SRPStateData(
        username: "testUserName",
        password: "testPassword",
        NHexValue: "",
        gHexValue: "",
        srpKeyPair: SRPKeys(publicKeyHexValue: "", privateKeyHexValue: ""),
        clientTimestamp: Date()
    )
}

extension InitiateAuthOutputResponse {
    static let testData = InitiateAuthOutputResponse(
        authenticationResult: .none,
        challengeName: .passwordVerifier,
        challengeParameters: nil,
        session: nil)

    static let validTestData = InitiateAuthOutputResponse(
        authenticationResult: .none,
        challengeName: .passwordVerifier,
        challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
        session: "session")

    static let invalidChallenge = InitiateAuthOutputResponse(
        authenticationResult: .none,
        challengeName: .passwordVerifier,
        challengeParameters: [:],
        session: nil)

    static let invalidTestDataWithNoSalt = InitiateAuthOutputResponse(
        authenticationResult: .none,
        challengeName: .passwordVerifier,
        challengeParameters: InitiateAuthOutputResponse.invalidChalengeParamsNoSalt,
        session: "session")

    static let invalidTestDataWithNoSecretBlock = InitiateAuthOutputResponse(
        authenticationResult: .none,
        challengeName: .passwordVerifier,
        challengeParameters: InitiateAuthOutputResponse.invalidChalengeParamsNoSecretBlock,
        session: "session")

    static let invalidTestDataWithNoSRPB = InitiateAuthOutputResponse(
        authenticationResult: .none,
        challengeName: .passwordVerifier,
        challengeParameters: InitiateAuthOutputResponse.invalidChalengeParamsNoSRPB,
        session: "session")

    static let invalidTestDataForException = InitiateAuthOutputResponse(
        authenticationResult: .none,
        challengeName: .passwordVerifier,
        challengeParameters: InitiateAuthOutputResponse.invalidChalengeParamsForException,
        session: "session")
}

extension RespondToAuthChallengeOutputResponse {
    static func testData() -> RespondToAuthChallengeOutputResponse {
        let result = CognitoIdentityProviderClientTypes.AuthenticationResultType(
            accessToken: "accessTokenXXX",
            expiresIn: 3_600,
            idToken: "idTokenXXX",
            newDeviceMetadata: nil,
            refreshToken: "refreshTokenXXX",
            tokenType: "Bearer")

        return RespondToAuthChallengeOutputResponse(
            authenticationResult: result,
            challengeName: .none,
            challengeParameters: [:],
            session: "session")
    }
}

extension SignInEvent {

    static let allStates: [SignInEvent] = [
        initiateSRPEvent,
        respondPasswordVerifierEvent,
        respondNextAuthChallengeEvent,
        finalizeSRPSignInEvent,
        cancelSRPSignInEvent,
        authErrorEvent,
        passwordVerifierErrorEvent,
        restoreToNotInitializedEvent
    ]

    static let initiateSRPEvent = SignInEvent(
        id: "initiateSRPEvent",
        eventType: .initiateSRP(.testData)
    )

    static let respondPasswordVerifierEvent = SignInEvent(
        id: "respondPasswordVerifierEvent",
        eventType: .respondPasswordVerifier(.testData, InitiateAuthOutputResponse.testData)
    )

    static let respondNextAuthChallengeEvent = SignInEvent(
        id: "respondNextAuthChallengeEvent",
        eventType: .respondNextAuthChallenge(RespondToAuthChallengeOutputResponse.testData())
    )

    static let finalizeSRPSignInEvent = SignInEvent(
        id: "finalizeSRPSignInEvent",
        eventType: .finalizeSRPSignIn(.testData)
    )

    static let cancelSRPSignInEvent = SignInEvent(
        id: "cancelSRPSignInEvent",
        eventType: .cancelSRPSignIn(.testData)
    )

    static let authErrorEvent = SignInEvent(
        id: "authErrorEvent",
        eventType: .throwAuthError(.testData)
    )

    static let passwordVerifierErrorEvent = SignInEvent(
        id: "passwordVerifierErrorEvent",
        eventType: .throwPasswordVerifierError(.testData)
    )

    static let restoreToNotInitializedEvent = SignInEvent(
        id: "restoreToNotInitializedEvent",
        eventType: .restoreToNotInitialized(.testData)
    )

}

extension SRPStateData {
    static let validStateData = SRPStateData(
        username: "royji2",
        password: "dummy123@",
        NHexValue:
            "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC7402" +
            "0BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F14374FE1" +
            "356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7EDEE386B" +
            "FB5A899FA5AE9F24117C4B1FE649286651ECE45B3DC2007CB8A163BF0598DA4836" +
            "1C55D39A69163FA8FD24CF5F83655D23DCA3AD961C62F356208552BB9ED5290770" +
            "96966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C180E" +
            "86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF6955817183995497CEA956A" +
            "E515D2261898FA051015728E5A8AAAC42DAD33170D04507A33A85521ABDF1CBA64" +
            "ECFB850458DBEF0A8AEA71575D060C7DB3970F85A6E1E4C7ABF5AE8CDB0933D71E" +
            "8C94E04A25619DCEE3D2261AD2EE6BF12FFA06D98A0864D87602733EC86A64521F" +
            "2B18177B200CBBE117577A615D6C770988C0BAD946E208E24FA074E5AB3143DB5B" +
            "FCE0FD108E4B82D120A93AD2CAFFFFFFFFFFFFFFFF",
        gHexValue: "2",
        srpKeyPair: SRPKeys(
            publicKeyHexValue:
                "3d68f89bcdd9658f3e9292edfab77d95ded899903a4fb5573477eb1bca2997cb5536" +
                "79cea2ed0cb2e61afa731683a2ec3c4b826ec90e39a45170928a139ec83691b47a6f" +
                "115244fe6cb2919c1f274ea6008c9b38a99471f00b6419688e5aa28cc157bf58e4dd" +
                "9f30803c76da06f3a4563d2bcc63e6d0f31aadabc9dff03d4f4b8519bbfce32ad427" +
                "4e84f3a5c48f3ba59997e31c92ab21e18928eae90af171881f23f1ac9105cad7e11d" +
                "a98eebd6ffb4f9b3131553f4d6320f71b786b97a5c51f81ec60969fc88f2ed70fbd6" +
                "bbd22728a9abdfe3c2766445b820d8b74f18ab28130252730c6666e593f2c6322b1f" +
                "02eb22cb6abc0649f7230446319fe5dcbbcca790422d126f73dee6a8d5fd7c160aa2" +
                "a22a9b334940176b515689c35d7a2737a73d8295b61892c5d9bb6a27743c227af7f2" +
                "1739014fed1802170702c5a034b2ff47d5a8d871db7e5bf51cb3ad29553101ed4cbd" +
                "98bab9079c01ab6acd0e75518d0cda640b9a1f011c9a7cefab68b6ddce666c874659" +
                "8a502c0e6adef0722bac",
            privateKeyHexValue: "c142c2d2471fd53bca99c2fdec84e522adec8ee2dcda0d9fff9dbea52ac4a65f"),
        clientTimestamp: Date(timeIntervalSinceReferenceDate: 656_187_908.969623)
    )
}
extension InitiateAuthOutputResponse {

    static let invalidChalengeParamsNoSalt: [String: String] = [
        "SALT": "",
        "SECRET_BLOCK": "a",
        "USER_ID_FOR_SRP": "royji2",
        "SRP_B": "a",
        "USERNAME": "a"
    ]

    static let invalidChalengeParamsNoSecretBlock: [String: String] = [
        "SALT": "a",
        "USER_ID_FOR_SRP": "royji2",
        "SRP_B": "a",
        "USERNAME": "a"]

    static let invalidChalengeParamsForException: [String: String] = [
        "SALT": "a",
        "SECRET_BLOCK": "",
        "USER_ID_FOR_SRP": "royji2",
        "SRP_B": "za",
        "USERNAME": "a"]

    static let invalidChalengeParamsNoSRPB: [String: String] = [
        "SALT": "a",
        "SECRET_BLOCK": "CDX6lsfSfPHwLUJpDSXIfkoLHEPmRc0e+g8riKvQzoqhA8UxgAKGQxx9NG5iKMpWtlRNqv" +
                        "iaz0SOm3smLgVYrzwbkMYlrtqD2E1PO9/1GSQsV/Kqddum/p+y4CMFujQZE4TWH/VbxD0B" +
                        "tZOfKL9M/dr1Pw7aOwxAlNKung5+KW3sFMdj7GNvU6MMNGXspx7u8d2L0de1GuAlF0YSxT" +
                        "E5NOrrFuatU/rPRetJN5c/vvgBZr+5eoGVdYLuDL/8gk2QHgS/+SIR88OBbs1h5zb8GKnh" +
                        "Qk/eib2PozCd96L/TTEGU0Lxg89UOnQ/HNQnNiKHBRym/1zUsNW0bjQex4K4y9Ap2tZJgO" +
                        "Dy5yzNrpa21mMskYK5Ryv8zn+G36Otp2tdWwGxV8MkJPyW56LLY5Gbbr3T5xOSUavVAGgG" +
                        "U/1ikV3V1BPITwikCpVZdxwnldNCBh98en60Uz+o9Q+k+/PtfbyhenfNCn61umTofEc78L" +
                        "o6SL9WRmkTyabBrR+iX4YjGBAyxURLChdhnA+StCkGq+cDmgJuMO9rAV1BWh4fMCvykQww" +
                        "6ZnFHHWkL3PSyPzfTiOIcnPT6QIb5jxDut/lZm5JJiyGi1FqjCjuhMrwKilwP92zm15WvG" +
                        "y74LWMVtwa5Qy+KwZS1cvNULGL9QaOs+H+xbI1Hu+heLPPUsfAFZwOH2vDlkmRSD1B7cSx" +
                        "tsY4Zb54j3+vrz1rT4EAWLZCwZ9OJhVPPK68llsH2NWKzKKbfvEdxwDNMXll2D1GCTkhvT" +
                        "w7jmuzKD5k4vQyvmLduuhr4NpyaAzgmNfVIljhjjz7yJjiF8/JKuPHMLMrBV8kXeJqlDfh" +
                        "qa/0sDKhkIdAcuGLPnUHiVWG5pdzyp0ELUwSwoS0p5HmOd8Mv/sXX/ZNqMDTTYm0G7IXrT" +
                        "tKWWQAvMw2bVMFC5f4fSbSpIoVjbTChumqLqDrT0zeC6whXT1NWL1RDrIyWN5BQBH5hpF5" +
                        "HPsxkPVEskQzeNjeFTvHA4sgSlbSVoSP8TnTkwwBxoLG6kH2JMn3ar5K2lCf2VSd+wcgzt" +
                        "AIVgiSc6eDVZEnXThX2j2ZJObPwcN7d21R1l6+FgH7XA7kbBWUV/dVchXuflNa+K2/ubmO" +
                        "/ofsasdw1+4JkJzjJVecX/KN/E79m1TDLzWSb1jnTrQpw5fCu+bAXtADzHdo7gynnek5gr" +
                        "9jzfZfPZ1Niu6/IVmTN/ClBt/hbr42VUnDw0liYqXe0/2m4ah2t/w1PYIeCnFUtNU+19Pf" +
                        "CzXnLOCwFwNNAj4JA7mX03nwvWKBMTjqv2Rx5h0dicuRZJKxjbzS/NrRjVTeaLJ+dg8iM0" +
                        "zXGxVGVNcc7WfmpngTDxGQyxUWeOTx53CL543xIZpTlsuR50uHc0/epmg5WpCQsKMAAyO3" +
                        "Fv2PRS378XaNMGNIyb7ZRuik+7IHbCNOB6B4Uqry3QJUg9dycsumcLqJw4Z3EvAuj5EMO6" +
                        "FMA0Gre8GVhICluhCmkNwbfe/UfsBSGffohGMMDHO/4IVn1pGiNRix6aAhiRdTtRgeFHq4" +
                        "fl/swCbhKecSbdzHlvCPjpfaidWI7ZYBALwTeWIDbFP21Rdk1BuU79bCwmuZ9No5y52oyA" +
                        "bA7jMS0q3ld4sAAw8YfRNf0KggdA9Iolz9qdI/8xVLTLWsdvv1NA1JIPb8lPtlkqTlFYDp" +
                        "inYbJk4W/1BOS85TSWPBwadRpVhEIDeH42hIgnvEPA==",
        "USER_ID_FOR_SRP": "royji2",
        "USERNAME": "a"]

    static let validChalengeParams: [String: String] = [
        "SALT": "79b00c90ebb6221ab4cad530f41441ed",
        "SECRET_BLOCK": "CDX6lsfSfPHwLUJpDSXIfkoLHEPmRc0e+g8riKvQzoqhA8UxgAKGQxx9NG5iKMpWtlRNqv" +
                        "iaz0SOm3smLgVYrzwbkMYlrtqD2E1PO9/1GSQsV/Kqddum/p+y4CMFujQZE4TWH/VbxD0B" +
                        "tZOfKL9M/dr1Pw7aOwxAlNKung5+KW3sFMdj7GNvU6MMNGXspx7u8d2L0de1GuAlF0YSxT" +
                        "E5NOrrFuatU/rPRetJN5c/vvgBZr+5eoGVdYLuDL/8gk2QHgS/+SIR88OBbs1h5zb8GKnh" +
                        "Qk/eib2PozCd96L/TTEGU0Lxg89UOnQ/HNQnNiKHBRym/1zUsNW0bjQex4K4y9Ap2tZJgO" +
                        "Dy5yzNrpa21mMskYK5Ryv8zn+G36Otp2tdWwGxV8MkJPyW56LLY5Gbbr3T5xOSUavVAGgG" +
                        "U/1ikV3V1BPITwikCpVZdxwnldNCBh98en60Uz+o9Q+k+/PtfbyhenfNCn61umTofEc78L" +
                        "o6SL9WRmkTyabBrR+iX4YjGBAyxURLChdhnA+StCkGq+cDmgJuMO9rAV1BWh4fMCvykQww" +
                        "6ZnFHHWkL3PSyPzfTiOIcnPT6QIb5jxDut/lZm5JJiyGi1FqjCjuhMrwKilwP92zm15WvG" +
                        "y74LWMVtwa5Qy+KwZS1cvNULGL9QaOs+H+xbI1Hu+heLPPUsfAFZwOH2vDlkmRSD1B7cSx" +
                        "tsY4Zb54j3+vrz1rT4EAWLZCwZ9OJhVPPK68llsH2NWKzKKbfvEdxwDNMXll2D1GCTkhvT" +
                        "w7jmuzKD5k4vQyvmLduuhr4NpyaAzgmNfVIljhjjz7yJjiF8/JKuPHMLMrBV8kXeJqlDfh" +
                        "qa/0sDKhkIdAcuGLPnUHiVWG5pdzyp0ELUwSwoS0p5HmOd8Mv/sXX/ZNqMDTTYm0G7IXrT" +
                        "tKWWQAvMw2bVMFC5f4fSbSpIoVjbTChumqLqDrT0zeC6whXT1NWL1RDrIyWN5BQBH5hpF5" +
                        "HPsxkPVEskQzeNjeFTvHA4sgSlbSVoSP8TnTkwwBxoLG6kH2JMn3ar5K2lCf2VSd+wcgzt" +
                        "AIVgiSc6eDVZEnXThX2j2ZJObPwcN7d21R1l6+FgH7XA7kbBWUV/dVchXuflNa+K2/ubmO" +
                        "/ofsasdw1+4JkJzjJVecX/KN/E79m1TDLzWSb1jnTrQpw5fCu+bAXtADzHdo7gynnek5gr" +
                        "9jzfZfPZ1Niu6/IVmTN/ClBt/hbr42VUnDw0liYqXe0/2m4ah2t/w1PYIeCnFUtNU+19Pf" +
                        "CzXnLOCwFwNNAj4JA7mX03nwvWKBMTjqv2Rx5h0dicuRZJKxjbzS/NrRjVTeaLJ+dg8iM0" +
                        "zXGxVGVNcc7WfmpngTDxGQyxUWeOTx53CL543xIZpTlsuR50uHc0/epmg5WpCQsKMAAyO3" +
                        "Fv2PRS378XaNMGNIyb7ZRuik+7IHbCNOB6B4Uqry3QJUg9dycsumcLqJw4Z3EvAuj5EMO6" +
                        "FMA0Gre8GVhICluhCmkNwbfe/UfsBSGffohGMMDHO/4IVn1pGiNRix6aAhiRdTtRgeFHq4" +
                        "fl/swCbhKecSbdzHlvCPjpfaidWI7ZYBALwTeWIDbFP21Rdk1BuU79bCwmuZ9No5y52oyA" +
                        "bA7jMS0q3ld4sAAw8YfRNf0KggdA9Iolz9qdI/8xVLTLWsdvv1NA1JIPb8lPtlkqTlFYDp" +
                        "inYbJk4W/1BOS85TSWPBwadRpVhEIDeH42hIgnvEPA==",
        "USER_ID_FOR_SRP": "royji2",
        "SRP_B": "b39ff004593719894a4d2d79146aa19be1e45992f44392fdf13dab2c4765ecefc8627f" +
                 "2e7ac8f30f136116f848f9606119ee4cd7e2e617caa21cf7c53b2e9b07bda875cf10f6" +
                 "9344c97916cd640b2a207bd54b28b2893c0f4d2273ecdc1f8bcd693f3d929e4038ae21" +
                 "7d0a83daa5c782879558e0e9c66b7d1e851801f5190e5c226dd613c5234740039f9ed1" +
                 "e732f2c4f57660025fd84275313f0b0a93642daeb2ab9f414a01fb973eaa9c9e940ff2" +
                 "e5ffb56e03171d88969f93d57c30afdead8c5ac095d9c0a94ce04dba97404f993821cf" +
                 "b7aa5b7e7d3461c4ef09462a3bdbc1002e3b9f2803a3dac11b2cbcb1353381ed35731a" +
                 "13f60adadb6b33cf3d31a2b102c507265cede30e5bc84bb0b6ed1005c1cdc72cf87efa" +
                 "96eec45283edfc75060a4bd0dc31544eb424cd25939626c014199ad433079b26a0ecab" +
                 "129c2eef61d22994ad70c96d286e6e8c1abc65e7060ba69cb0d8c4a31cc08cc7d76ef9" +
                 "2f757b2a34e7ae236aadbced9bb7a4a06e67da3a084833e0f3a0b903af0a74816031",
        "USERNAME": "royji2"]

    static let validSMSChallengeParams: [String: String] = [
        "CODE_DELIVERY_DELIVERY_MEDIUM": "SMS",
        "CODE_DELIVERY_DESTINATION": "123"
    ]
}
