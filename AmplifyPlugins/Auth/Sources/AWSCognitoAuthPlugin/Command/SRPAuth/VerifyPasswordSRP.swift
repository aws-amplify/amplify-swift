//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import hierarchical_state_machine_swift
import AWSCognitoIdentityProvider
import Foundation
import CryptoKit

struct VerifyPasswordSRP: Command {
    let identifier = "VerifyPasswordSRP"

    let stateData: SRPStateData
    let authResponse: InitiateAuthOutputResponse

    init(stateData: SRPStateData,
         authResponse: InitiateAuthOutputResponse)
    {
        self.stateData = stateData
        self.authResponse = authResponse
    }

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        guard let environment = environment as? SRPAuthEnvironment else {
            let authError = AuthenticationError.configuration(message: "Environment configured incorrectly")
            let event = SRPSignInEvent(
                id: UUID().uuidString,
                eventType: .throwPasswordVerifierError(authError)
            )
            dispatcher.send(event)
            return
        }

        guard let challengeParameters = authResponse.challengeParameters else {
            let authError = AuthenticationError.service(message: "Unable to retrieve auth response challenge params")
            let event = SRPSignInEvent(
                id: environment.eventIDFactory(),
                eventType: .throwPasswordVerifierError(authError)
            )
            dispatcher.send(event)
            return
        }

        let username = challengeParameters["USERNAME"] ?? stateData.username
        let userIdForSRP = challengeParameters["USER_ID_FOR_SRP"] ?? stateData.username

        guard let saltHex = challengeParameters["SALT"],
              !saltHex.isEmpty else {
                  let authError = AuthenticationError.service(message: "Unable to retrieve salt")
                  let event = SRPSignInEvent(
                    id: environment.eventIDFactory(),
                    eventType: .throwPasswordVerifierError(authError)
                  )
                  dispatcher.send(event)
                  return
              }

        guard let secretBlockString = challengeParameters["SECRET_BLOCK"],
              let serverSecretBlock = Data(base64Encoded: secretBlockString)
        else {
                  let authError = AuthenticationError.service(message: "Unable to retrieve server secrets")
                  let event = SRPSignInEvent(
                      id: environment.eventIDFactory(),
                      eventType: .throwPasswordVerifierError(authError)
                  )
                  dispatcher.send(event)
                  return
              }

        guard let serverPublicBHexString = challengeParameters["SRP_B"] else {
                  let authError = AuthenticationError.service(message: "Unable to retrieve SRP_B")
                  let event = SRPSignInEvent(
                      id: environment.eventIDFactory(),
                      eventType: .throwPasswordVerifierError(authError)
                  )
                  dispatcher.send(event)
                  return
              }
        let userPoolClientId = environment.userPoolConfiguration.clientId
        let poolId = environment.userPoolConfiguration.poolId


        let session = authResponse.session

        var challengeResponses = ["USERNAME": username]

        if let clientSecretHash = generateClientSecretHash(environment: environment,
                                                           userPoolClientId: userPoolClientId)
        {
            challengeResponses["SECRET_HASH"] = clientSecretHash
        }

        do {

            let index = poolId.firstIndex(of: "_")!
            let strippedPoolId =  poolId[poolId.index(index, offsetBy: 1)...]
            let dateStr = generateDateString(date: stateData.clientTimestamp)
            let usernameForS = "\(strippedPoolId)\(userIdForSRP)"

            let srpClient = try environment.srpClientFactory(environment.srpConfiguration.nHexValue,
                                                             environment.srpConfiguration.gHexValue)
            // Calculate the S value
            let clientSharedSecret = try srpClient.calculateSharedSecret(username: usernameForS,
                                                                         password: stateData.password,
                                                                         saltHexValue: saltHex,
                                                                         clientPrivateKeyHexValue: stateData.srpKeyPair.privateKeyHexValue,
                                                                         clientPublicKeyHexValue: stateData.srpKeyPair.publicKeyHexValue,
                                                                         serverPublicKeyHexValue: serverPublicBHexString)

            let u = try type(of: srpClient).calculateUHexValue(
                clientPublicKeyHexValue: stateData.srpKeyPair.publicKeyHexValue,
                serverPublicKeyHexValue: serverPublicBHexString)
            // HKDF
            let authenticationkey = try type(of: srpClient).generateAuthenticationKey(
                sharedSecretHexValue: clientSharedSecret,
                uHexValue: u)

            // Signature

            let signature = generateAuthenticationSignature(srpTimeStamp: dateStr,
                                                            authenticationKey: authenticationkey,
                                                            srpUserName: userIdForSRP,
                                                            poolName: String(strippedPoolId),
                                                            serviceSecretBlock: serverSecretBlock)
            let signatureString = signature.base64EncodedString()

            challengeResponses["TIMESTAMP"] = dateStr
            challengeResponses["PASSWORD_CLAIM_SECRET_BLOCK"] = secretBlockString
            challengeResponses["PASSWORD_CLAIM_SIGNATURE"] = signatureString

        } catch {
            let authError = AuthenticationError.service(message: "Exception calculating secret")
            let event = SRPSignInEvent(
                id: environment.eventIDFactory(),
                eventType: .throwPasswordVerifierError(authError)
            )
            dispatcher.send(event)
        }

        let input = RespondToAuthChallengeInput(analyticsMetadata: nil,
                                                challengeName: .passwordVerifier,
                                                challengeResponses: challengeResponses,
                                                clientId: userPoolClientId,
                                                clientMetadata: nil,
                                                session: session,
                                                userContextData: nil)

        do {
            let client = try environment.cognitoUserPoolFactory()
            timer.note("### starting respondToAuthChallenge")
            client.respondToAuthChallenge(input: input) { result in
                timer.note("### respondToAuthChallenge response received")

                switch result {
                case .success(let response):
                    if let authenticationResult = response.authenticationResult {
                        
                        guard let idToken = authenticationResult.idToken,
                              let accessToken = authenticationResult.accessToken,
                              let refreshToken = authenticationResult.refreshToken else {
                            fatalError("TODO: Replace this with a dispatcher.send()")
                        }
                        
                        let userPoolTokens = AWSCognitoUserPoolTokens(
                            idToken: idToken,
                            accessToken: accessToken,
                            refreshToken: refreshToken,
                            expiresIn: authenticationResult.expiresIn
                        )
                        
                        let signedInData = SignedInData(
                            userId: "",
                            userName: stateData.username,
                            signedInDate: Date(),
                            signInMethod: .srp,
                            cognitoUserPoolTokens: userPoolTokens
                        )
                        let event = SRPSignInEvent(
                            id: environment.eventIDFactory(),
                            eventType: .finalizeSRPSignIn(signedInData),
                            time: Date()
                        )
                        timer.stop("### sending SRPSignInEvent.done")
                        dispatcher.send(event)
                    }
                case .failure(let error):
                    print(error)
                    let authError = AuthenticationError.service(message: error.localizedDescription)
                    let event = SRPSignInEvent(
                        id: environment.eventIDFactory(),
                        eventType: .throwPasswordVerifierError(authError)
                    )
                    dispatcher.send(event)
                }
                timer.stop("### sending SRPSignInEvent.resondToAuthChallengeResponseReceived")
            }
        } catch {
            let authError = AuthenticationError.service(message: "Exception responding to auth challenge")
            let event = SRPSignInEvent(
                id: environment.eventIDFactory(),
                eventType: .throwPasswordVerifierError(authError)
            )
            dispatcher.send(event)
        }

    }

    private static func getClientSecretHashBase64String(
        username: String,
        userPoolClientId: String,
        clientSecret: String
    ) -> String {
        let clientSecretData = clientSecret.data(using: .utf8)!
        let clientSecretByteArray = [UInt8](clientSecretData)
        let key = SymmetricKey(data: clientSecretByteArray)

        let clientData = (username + userPoolClientId).data(using: .utf8)!

        let mac = HMAC<SHA256>.authenticationCode(for: clientData, using: key)
        let macBase64 = Data(mac).base64EncodedString()
        return macBase64
    }

    private func generateAuthenticationSignature(srpTimeStamp: String,
                                                 authenticationKey: Data,
                                                 srpUserName: String,
                                                 poolName: String,
                                                 serviceSecretBlock: Data) -> Data
    {
        let key = SymmetricKey(data: authenticationKey)
        var hmac = HMAC<SHA256>.init(key: key)
        hmac.update(data: poolName.data(using: .utf8)!)
        hmac.update(data: srpUserName.data(using: .utf8)!)
        hmac.update(data: serviceSecretBlock)
        hmac.update(data: srpTimeStamp.data(using: .utf8)!)
        return Data(hmac.finalize())
    }

    private func generateDateString(date: Date) -> String {
        let timezone = TimeZone(abbreviation: "UTC")
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timezone
        dateFormatter.dateFormat = "EEE MMM d HH:mm:ss 'UTC' yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: date)
    }

    private func generateClientSecretHash(environment: SRPAuthEnvironment, userPoolClientId: String) -> String? {
        if let appClientSecret = environment.userPoolConfiguration.clientSecret {
            let clientSecretHash = VerifyPasswordSRP.getClientSecretHashBase64String(
                username: stateData.username,
                userPoolClientId: userPoolClientId,
                clientSecret: appClientSecret
            )
            return clientSecretHash
        }
        return nil
    }
}

extension VerifyPasswordSRP: DefaultLogger { }

extension VerifyPasswordSRP: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "stateData": stateData.debugDictionary,
            "authResponse": authResponse
        ]
    }
}

extension VerifyPasswordSRP: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
