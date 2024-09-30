package software.amazon.smithy.aws.swift.codegen.customization

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.SourceLocation
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.traits.AuthTrait
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.expectShape

internal val DISABLED_AUTH_OPERATIONS: Map<String, Set<String>> = mapOf(
    "com.amazonaws.sts#AWSSecurityTokenServiceV20110615" to setOf(
        "com.amazonaws.sts#AssumeRoleWithSAML",
        "com.amazonaws.sts#AssumeRoleWithWebIdentity"
    ),
    // Operations with missing optional auth: https://docs.aws.amazon.com/cognito/latest/developerguide/security_iam_service-with-iam.html
    //
    // Some of the following operations do correctly have the `optionalAuth` trait applied and therefore do not need this customization
    // but maintaining the diff of operations that have the trait and which don't is a nightmare and so
    // we are applying the trait to all operations listed in the documentation linked above.
    "com.amazonaws.cognitoidentity#AWSCognitoIdentityService" to setOf(
        "com.amazonaws.cognitoidentity#GetId",
        "com.amazonaws.cognitoidentity#GetOpenIdToken",
        "com.amazonaws.cognitoidentity#UnlinkIdentity",
        "com.amazonaws.cognitoidentity#GetCredentialsForIdentity",
    ),
    "com.amazonaws.cognitoidentityprovider#AWSCognitoIdentityProviderService" to setOf(
        "com.amazonaws.cognitoidentityprovider#AssociateSoftwareToken",
        "com.amazonaws.cognitoidentityprovider#ChangePassword",
        "com.amazonaws.cognitoidentityprovider#ConfirmDevice",
        "com.amazonaws.cognitoidentityprovider#ConfirmForgotPassword",
        "com.amazonaws.cognitoidentityprovider#ConfirmSignUp",
        "com.amazonaws.cognitoidentityprovider#DeleteUser",
        "com.amazonaws.cognitoidentityprovider#DeleteUserAttributes",
        "com.amazonaws.cognitoidentityprovider#ForgetDevice",
        "com.amazonaws.cognitoidentityprovider#ForgotPassword",
        "com.amazonaws.cognitoidentityprovider#GetDevice",
        "com.amazonaws.cognitoidentityprovider#GetUser",
        "com.amazonaws.cognitoidentityprovider#GetUserAttributeVerificationCode",
        "com.amazonaws.cognitoidentityprovider#GlobalSignOut",
        "com.amazonaws.cognitoidentityprovider#InitiateAuth",
        "com.amazonaws.cognitoidentityprovider#ListDevices",
        "com.amazonaws.cognitoidentityprovider#ResendConfirmationCode",
        "com.amazonaws.cognitoidentityprovider#RespondToAuthChallenge",
        "com.amazonaws.cognitoidentityprovider#RevokeToken",
        "com.amazonaws.cognitoidentityprovider#SetUserMFAPreference",
        "com.amazonaws.cognitoidentityprovider#SetUserSettings",
        "com.amazonaws.cognitoidentityprovider#SignUp",
        "com.amazonaws.cognitoidentityprovider#UpdateAuthEventFeedback",
        "com.amazonaws.cognitoidentityprovider#UpdateDeviceStatus",
        "com.amazonaws.cognitoidentityprovider#UpdateUserAttributes",
        "com.amazonaws.cognitoidentityprovider#VerifySoftwareToken",
        "com.amazonaws.cognitoidentityprovider#VerifyUserAttribute",
    )
)
// TODO: If or when the service team adds this trait to their model, we can remove this customization
class DisabledAuth(private val disabledAuth: Map<String, Set<String>> = DISABLED_AUTH_OPERATIONS) : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        val currentServiceId = model.expectShape<ServiceShape>(settings.service).id.toString()
        return disabledAuth.keys.contains(currentServiceId)
    }

    override fun preprocessModel(model: Model, settings: SwiftSettings): Model {
        val currentServiceId = model.expectShape<ServiceShape>(settings.service).id.toString()
        val disabledAuthOperations = disabledAuth[currentServiceId]!!
        return ModelTransformer.create().mapShapes(model) {
            if (disabledAuthOperations.contains(it.id.toString()) && it is OperationShape) {
                it.toBuilder().addTrait(AuthTrait(setOf(), SourceLocation.NONE)).build()
            } else {
                it
            }
        }
    }
}
