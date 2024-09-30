/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.rulesengine.language.EndpointRuleSet
import software.amazon.smithy.rulesengine.language.evaluation.value.ArrayValue
import software.amazon.smithy.rulesengine.language.evaluation.value.BooleanValue
import software.amazon.smithy.rulesengine.language.evaluation.value.EmptyValue
import software.amazon.smithy.rulesengine.language.evaluation.value.IntegerValue
import software.amazon.smithy.rulesengine.language.evaluation.value.RecordValue
import software.amazon.smithy.rulesengine.language.evaluation.value.StringValue
import software.amazon.smithy.rulesengine.language.evaluation.value.Value
import software.amazon.smithy.rulesengine.traits.EndpointTestsTrait
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.endpoints.EndpointTypes
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTestUtilTypes
import software.amazon.smithy.swift.codegen.swiftmodules.XCTestTypes
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

/**
 * Generates code for EndpointResolver tests.
 */
class EndpointTestGenerator(
    private val endpointTest: EndpointTestsTrait,
    private val endpointRuleSet: EndpointRuleSet?,
    private val ctx: ProtocolGenerator.GenerationContext
) {
    fun render(writer: SwiftWriter): Int {
        if (endpointTest.testCases.isEmpty()) { return 0 }

        writer.addImport(ctx.settings.moduleName, isTestable = true)
        writer.addImport(SwiftDependency.XCTest.target)

        // used to filter out test params that are not valid
        val endpointParamsMembers = endpointRuleSet?.parameters?.toList()?.map { it.name.name.value }?.toSet() ?: emptySet()

        var count = 0
        writer.openBlock("class EndpointResolverTest: \$N {", "}", XCTestTypes.XCTestCase) {
            writer.write("")
            writer.openBlock("override class func setUp() {", "}") {
                writer.write("\$N.initialize()", SmithyTestUtilTypes.TestInitializer)
            }
            writer.write("")

            endpointTest.testCases.forEach { testCase ->
                writer.write("/// \$L", testCase.documentation)
                writer.openBlock("func testResolve${++count}() throws {", "}") {
                    writer.openBlock("let endpointParams = \$N(", ")", EndpointTypes.EndpointParams) {
                        val applicableParams =
                            testCase.params.members.filter { endpointParamsMembers.contains(it.key.value) }
                                .toSortedMap(compareBy { it.value }).map { (key, value) ->
                                    key to value
                                }

                        applicableParams.forEachIndexed { idx, pair ->
                            writer.writeInline("${pair.first.value.toLowerCamelCase()}: ")
                            val value = Value.fromNode(pair.second)
                            writer.call {
                                generateValue(
                                    writer, value, if (idx < applicableParams.count() - 1) "," else "", false
                                )
                            }
                        }
                    }
                    writer.write("let resolver = try \$N()", EndpointTypes.DefaultEndpointResolver).write("")

                    testCase.expect.error.ifPresent { error ->
                        writer.openBlock(
                            "XCTAssertThrowsError(try resolver.resolve(params: endpointParams)) { error in", "}"
                        ) {
                            writer.openBlock("switch error {", "}") {
                                writer.dedent().write("case \$N.unresolved(let message):", ClientRuntimeTypes.Core.EndpointError)
                                writer.indent().write("XCTAssertEqual(\$S, message)", error)
                                writer.dedent().write("default:")
                                writer.indent().write("XCTFail()")
                            }
                        }
                    }
                    testCase.expect.endpoint.ifPresent { endpoint ->
                        writer.write("let actual = try resolver.resolve(params: endpointParams)").write("")

                        // [String: AnyHashable] can't be constructed from a dictionary literal
                        // first create a string JSON string literal
                        // then convert to [String: AnyHashable] using JSONSerialization.jsonObject(with:)
                        writer.openBlock("let properties: [String: AnyHashable] = ", "") {
                            generateProperties(writer, endpoint.properties)
                        }

                        val reference = if (endpoint.headers.isNotEmpty()) "var" else "let"
                        writer.write("$reference headers = \$N()", SmithyHTTPAPITypes.Headers)
                        endpoint.headers.forEach { (name, values) ->
                            writer.write("headers.add(name: \$S, values: [\$S])", name, values.sorted().joinToString(","))
                        }
                        writer.write(
                            "let expected = try \$N(urlString: \$S, headers: headers, properties: properties)",
                            SmithyHTTPAPITypes.Endpoint,
                            endpoint.url
                        ).write("")
                        writer.write("XCTAssertEqual(expected, actual)")
                    }
                }
                writer.write("")
            }
        }

        return count
    }

    /**
     * Recursively traverse map of properties and generate JSON string literal.
     */
    private fun generateProperties(writer: SwiftWriter, properties: Map<String, Node>) {
        if (properties.isEmpty()) {
            writer.write("[:]")
        } else {
            writer.openBlock("[", "]") {
                properties.map { it.key to it.value }.forEachIndexed { idx, (first, second) ->
                    val value = Value.fromNode(second)
                    writer.writeInline("\$S: ", first)
                    writer.call {
                        generateValue(writer, value, if (idx < properties.values.count() - 1) "," else "", true)
                    }
                }
            }
        }
    }

    /**
     * Recursively traverse the value and render a JSON string literal.
     */
    private fun generateValue(writer: SwiftWriter, value: Value, delimeter: String, castToAnyHashable: Boolean) {
        when (value) {
            is StringValue -> {
                writer.write("\$S$delimeter", value.toString())
            }

            is IntegerValue -> {
                writer.write("\$L$delimeter", value.toString())
            }

            is BooleanValue -> {
                writer.write("\$L$delimeter", value.toString())
            }

            is EmptyValue -> {
                writer.write("nil$delimeter")
            }

            is ArrayValue -> {
                val castStmt = if (castToAnyHashable) " as [AnyHashable]$delimeter" else ""
                writer.openBlock("[", "]$castStmt") {
                    value.values.forEachIndexed { idx, item ->
                        writer.call {
                            generateValue(writer, item, if (idx < value.values.count() - 1) "," else "", castToAnyHashable)
                        }
                    }
                }
            }

            is RecordValue -> {
                if (value.value.isEmpty()) {
                    writer.writeInline("[:]")
                } else {
                    writer.openBlock("[", "] as [String: AnyHashable]$delimeter") {
                        value.value.map { it.key to it.value }.forEachIndexed { idx, (first, second) ->
                            writer.writeInline("\$S: ", first.name)
                            writer.call {
                                generateValue(writer, second, if (idx < value.value.count() - 1) "," else "", castToAnyHashable)
                            }
                        }
                    }
                }
            }

            else -> {
                throw CodegenException("Unsupported value type: $value")
            }
        }
    }
}
