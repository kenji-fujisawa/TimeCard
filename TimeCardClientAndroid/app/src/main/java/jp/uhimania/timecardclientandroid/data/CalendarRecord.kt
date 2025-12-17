package jp.uhimania.timecardclientandroid.data

import androidx.compose.runtime.saveable.Saver
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.util.Date

@Serializable
data class CalendarRecord(
    @Serializable(DateSerializer::class) val date: Date,
    val records: List<TimeRecord>
)

val CalendarRecordSaver = Saver<CalendarRecord, String>(
    save = {
        Json.encodeToString(it)
    },
    restore = {
        Json.decodeFromString(it)
    }
)
