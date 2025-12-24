package jp.uhimania.timecardclientandroid.data

import android.util.Log
import jp.uhimania.timecardclientandroid.data.source.LocalBreakTime
import jp.uhimania.timecardclientandroid.data.source.LocalDataSource
import jp.uhimania.timecardclientandroid.data.source.LocalTimeRecord
import jp.uhimania.timecardclientandroid.data.source.NetworkDataSource
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.withContext
import java.util.Calendar

interface CalendarRecordRepository {
    fun getRecords(year: Int, month: Int): Flow<List<CalendarRecord>>

    suspend fun updateRecord(source: List<CalendarRecord>, record: CalendarRecord)
}

class DefaultCalendarRecordRepository(
    private val networkDataSource: NetworkDataSource,
    private val localDataSource: LocalDataSource,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO
) : CalendarRecordRepository {
    override fun getRecords(year: Int, month: Int): Flow<List<CalendarRecord>> {
        return localDataSource.getRecords(year, month)
            .map { it.map { entry -> entry.toTimeRecord() } }
            .map {
                val records = it.groupBy { rec -> rec.checkIn?.day() }
                val dates = Calendar.getInstance().datesOf(year, month)
                dates.map { date ->
                    CalendarRecord(
                        date = date,
                        records = records[date.day()] ?: listOf()
                    )
                }
            }
            .onStart { fetchRecords(year, month) }
            .flowOn(dispatcher)
    }

    private suspend fun fetchRecords(year: Int, month: Int) {
        withContext(dispatcher) {
            try {
                val records = networkDataSource.getRecords(year, month)
                localDataSource.deleteRecords(year, month)
                records.forEach { record ->
                    localDataSource.insert(record.toLocal())
                    record.localBreakTimes().forEach { localDataSource.insert(it) }
                }
            } catch (ex: Exception) {
                Log.d(TAG, ex.toString())
            }
        }
    }

    override suspend fun updateRecord(source: List<CalendarRecord>, record: CalendarRecord) {
        val before = source.find { it.date == record.date }
        if (before == null) {
            return
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

        for (rec in inserted) {
            val record = networkDataSource.insertRecord(rec)
            localDataSource.insert(record.toLocal())
            record.localBreakTimes().forEach { localDataSource.insert(it) }
        }
        for (rec in updated) {
            val record = networkDataSource.updateRecord(rec)
            localDataSource.delete(rec.toLocal())
            localDataSource.insert(record.toLocal())
            record.localBreakTimes().forEach { localDataSource.insert(it) }
        }
        for (rec in deleted) {
            networkDataSource.deleteRecord(rec)
            localDataSource.delete(rec.toLocal())
        }
    }

    companion object {
        val TAG = DefaultCalendarRecordRepository::class.simpleName
    }
}

fun Map.Entry<LocalTimeRecord, List<LocalBreakTime>>.toTimeRecord(): TimeRecord {
    return TimeRecord(
        id = this.key.id,
        checkIn = this.key.checkIn,
        checkOut = this.key.checkOut,
        breakTimes = this.value.map {
            BreakTime(
                id = it.id,
                start = it.start,
                end = it.end
            )
        }.toList()
    )
}

fun TimeRecord.toLocal(): LocalTimeRecord {
    return LocalTimeRecord(
        id = this.id,
        year = this.checkIn?.year() ?: 0,
        month = this.checkIn?.month() ?: 0,
        checkIn = this.checkIn,
        checkOut = this.checkOut
    )
}

fun TimeRecord.localBreakTimes(): List<LocalBreakTime> {
    return this.breakTimes.map {
        LocalBreakTime(
            id = it.id,
            start = it.start,
            end = it.end,
            timeRecordId = this.id
        )
    }
}
