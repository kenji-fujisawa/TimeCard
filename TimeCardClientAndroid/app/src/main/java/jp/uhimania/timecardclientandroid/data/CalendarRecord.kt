package jp.uhimania.timecardclientandroid.data

import kotlinx.serialization.Serializable
import java.util.Date

@Serializable
data class CalendarRecord(
    @Serializable(DateSerializer::class) val date: Date,
    val records: List<TimeRecord>
)
