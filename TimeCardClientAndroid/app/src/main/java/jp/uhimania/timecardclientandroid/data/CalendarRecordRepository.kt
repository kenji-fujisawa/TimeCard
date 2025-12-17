package jp.uhimania.timecardclientandroid.data

import jp.uhimania.timecardclientandroid.data.source.NetworkDataSource
import java.util.Calendar

interface CalendarRecordRepository {
    suspend fun getRecords(year: Int, month: Int): List<CalendarRecord>

    suspend fun updateRecord(source: List<CalendarRecord>, record: CalendarRecord): List<CalendarRecord>
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

    override suspend fun updateRecord(source: List<CalendarRecord>, record: CalendarRecord): List<CalendarRecord> {
        val before = source.find { it.date == record.date }
        if (before == null) {
            return source
        }

        val inserted = record.records.filter { item ->
            before.records.find { item.id == it.id } == null
        }
        val updated = record.records.filter { item ->
            val rec = before.records.find { item.id == it.id }
            rec != null && rec != item
        }
        val deleted = before.records.filter { item ->
            record.records.find { item.id == it.id } == null
        }
        val notChanged = record.records.filter { item ->
            val rec = before.records.find { item.id == it.id }
            rec != null && rec == item
        }

        val result = mutableListOf<TimeRecord>()
        result.addAll(notChanged)
        for (rec in inserted) {
            result.add(networkDataSource.insertRecord(rec))
        }
        for (rec in updated) {
            result.add(networkDataSource.updateRecord(rec))
        }
        for (rec in deleted) {
            networkDataSource.deleteRecord(rec)
        }

        result.sortBy { it.checkIn }
        val after = before.copy(records = result.toList())
        val index = source.indexOf(before)
        val recs = source.toMutableList()
        recs[index] = after
        return recs.toList()
    }
}
