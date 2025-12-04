package jp.uhimania.timecardclientandroid.data

import java.util.Date

data class CalendarRecord(
    val date: Date,
    val records: List<TimeRecord>
)
