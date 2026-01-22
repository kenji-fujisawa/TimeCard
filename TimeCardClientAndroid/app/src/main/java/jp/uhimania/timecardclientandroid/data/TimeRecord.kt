package jp.uhimania.timecardclientandroid.data

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.Serializer
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

@Serializable
data class BreakTime @OptIn(ExperimentalUuidApi::class) constructor(
    val id: String = Uuid.random().toString(),
    @Serializable(DateSerializer::class) val start: Date?,
    @Serializable(DateSerializer::class) val end: Date?
)

@Serializable
data class TimeRecord @OptIn(ExperimentalUuidApi::class) constructor(
    val id: String = Uuid.random().toString(),
    @Serializable(DateSerializer::class) val checkIn: Date?,
    @Serializable(DateSerializer::class) val checkOut: Date?,
    val breakTimes: List<BreakTime>
)

@OptIn(ExperimentalSerializationApi::class)
@Serializer(Date::class)
class DateSerializer : KSerializer<Date> {
    val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX", Locale.getDefault())

    override fun serialize(encoder: Encoder, value: Date) {
        encoder.encodeString(formatter.format(value))
    }

    override fun deserialize(decoder: Decoder): Date {
        return formatter.parse(decoder.decodeString()) ?: Date()
    }
}
