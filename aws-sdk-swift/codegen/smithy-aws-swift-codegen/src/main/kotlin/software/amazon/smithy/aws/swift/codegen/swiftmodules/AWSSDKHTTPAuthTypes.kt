package software.amazon.smithy.aws.swift.codegen.swiftmodules

import software.amazon.smithy.aws.swift.codegen.AWSSwiftDependency
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftSymbol

object AWSSDKHTTPAuthTypes {
    val SigV4AuthScheme = runtimeSymbol("SigV4AuthScheme", SwiftDeclaration.STRUCT)
    val SigV4AAuthScheme = runtimeSymbol("SigV4AAuthScheme", SwiftDeclaration.STRUCT)
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    AWSSwiftDependency.AWS_SDK_HTTP_AUTH,
    emptyList(),
    emptyList(),
)
