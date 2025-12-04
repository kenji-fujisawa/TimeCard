package jp.uhimania.timecardclientandroid.data

import jp.uhimania.timecardclientandroid.data.source.NetworkDataSource
import java.util.Calendar

interface CalendarRecordRepository {
    suspend fun getRecords(year: Int, month: Int): List<CalendarRecord>
}

class DefaultCalendarRecordRepository(
    private val networkDataSource: NetworkDataSource
) : CalendarRecordRepository {
    override suspend fun getRecords(year: Int, month: Int): List<CalendarRecord> {
        val dates = Calendar.getInstance().datesOf(year, month)

        val records = networkDataSource.getRecords(year, month).groupBy {
            it.checkIn?.day()
        }

        return dates.map {
            CalendarRecord(
                date = it,
                records = records[it.day()] ?: listOf()
            )
        }
    }
}
