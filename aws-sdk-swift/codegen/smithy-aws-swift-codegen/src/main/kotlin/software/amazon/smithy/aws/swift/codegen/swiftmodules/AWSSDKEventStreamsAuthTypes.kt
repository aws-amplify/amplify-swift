package software.amazon.smithy.aws.swift.codegen.swiftmodules

import software.amazon.smithy.aws.swift.codegen.AWSSwiftDependency
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftSymbol

object AWSSDKEventStreamsAuthTypes {
    val setupBidirectionalStreaming = runtimeSymbol("setupBidirectionalStreaming", SwiftDeclaration.FUNC)
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    AWSSwiftDependency.AWS_SDK_EVENT_STREAMS_AUTH,
    emptyList(),
    emptyList(),
)
