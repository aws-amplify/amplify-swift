package software.amazon.smithy.aws.swift.codegen.model

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.DeprecatedTrait
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.getTrait
import java.time.DateTimeException
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.function.Predicate

private val DEPRECATED_SINCE_DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd")

private val REMOVE_BEFORE_DATE = "2024-09-17"

/**
 * Parses a string of yyyy-MM-dd format to [LocalDate], returning `null` if parsing fails.
 */
internal fun String.toLocalDate(): LocalDate? = try { LocalDate.parse(this, DEPRECATED_SINCE_DATE_FORMATTER) } catch (e: DateTimeException) { null }

class AWSDeprecatedShapeRemover : SwiftIntegration {
    override fun preprocessModel(model: Model, settings: SwiftSettings): Model {
        return ModelTransformer.create().removeShapesIf(
            model,
            Predicate<Shape> {
                val since = it.getTrait<DeprecatedTrait>()?.since?.orElse(null) ?: return@Predicate false
                val deprecatedDate = since.toLocalDate() ?: return@Predicate false.also {
                    println("Could not parse `since` field \"$since\" as a date, skipping removal of deprecated shape $it")
                }
                return@Predicate deprecatedDate < REMOVE_BEFORE_DATE.toLocalDate()
            }
        )
    }
}
