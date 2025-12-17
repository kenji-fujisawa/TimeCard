package jp.uhimania.timecardclientandroid.data

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.Serializer
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.util.Calendar
import java.util.Date
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
    override fun serialize(encoder: Encoder, value: Date) {
        val calendar = Calendar.getInstance()
        calendar.time = value
        calendar.add(Calendar.YEAR, 1970 - 2001)
        encoder.encodeDouble(calendar.time.time.toDouble() / 1000)
    }

    override fun deserialize(decoder: Decoder): Date {
        val calendar = Calendar.getInstance()
        calendar.time = Date((decoder.decodeDouble() * 1000).toLong())
        calendar.add(Calendar.YEAR, 2001 - 1970)
        return calendar.time
    }
}
