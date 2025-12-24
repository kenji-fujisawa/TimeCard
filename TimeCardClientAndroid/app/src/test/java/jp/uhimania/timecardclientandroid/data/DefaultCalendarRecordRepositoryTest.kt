package jp.uhimania.timecardclientandroid.data

import jp.uhimania.timecardclientandroid.data.source.LocalBreakTime
import jp.uhimania.timecardclientandroid.data.source.LocalDataSource
import jp.uhimania.timecardclientandroid.data.source.LocalTimeRecord
import jp.uhimania.timecardclientandroid.data.source.NetworkDataSource
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Calendar

class DefaultCalendarRecordRepositoryTest {
    @Test
    fun testGetRecords() = runTest {
        val network = FakeNetworkDataSource()
        val local = FakeLocalDataSource()
        val repository = DefaultCalendarRecordRepository(network, local)
        val records = repository.getRecords(2025, 12).first()
        assertEquals(31, records.count())

        for (i in 0..<31) {
            assertEquals(2025, records[i].date.year())
            assertEquals(12, records[i].date.month())
            assertEquals(i + 1, records[i].date.day())

            when (i + 1) {
                4 -> {
                    assertEquals(2, records[i].records.count())
                    assertEquals(local.records[0], records[i].records[0])
                    assertEquals(local.records[1], records[i].records[1])
                }
                5 -> {
                    assertEquals(1, records[i].records.count())
                    assertEquals(local.records[2], records[i].records[0])
                }
                else -> {
                    assertEquals(0, records[i].records.count())
                }
            }
        }

        assertEquals(2025, local.deleteYear)
        assertEquals(12, local.deleteMonth)

        assertEquals(2025, network.getRecordsYear)
        assertEquals(12, network.getRecordsMonth)

        val recs = local.getRecords(2025, 12).first()
        assertEquals(3, local.insertedTimeRecords.count())
        assertEquals(recs.keys.toList()[0], local.insertedTimeRecords[0])
        assertEquals(recs.keys.toList()[1], local.insertedTimeRecords[1])
        assertEquals(recs.keys.toList()[2], local.insertedTimeRecords[2])

        assertEquals(3, local.insertedBreakTimes.count())
        assertEquals(recs.values.toList()[0][0], local.insertedBreakTimes[0])
        assertEquals(recs.values.toList()[0][1], local.insertedBreakTimes[1])
        assertEquals(recs.values.toList()[1][0], local.insertedBreakTimes[2])
    }

    @Test
    fun testUpdateRecord() = runTest {
        val records = Calendar.getInstance().datesOf(2025, 12).map {
            CalendarRecord(
                date = it,
                records = listOf(
                    TimeRecord(
                        checkIn = it,
                        checkOut = it,
                        breakTimes = listOf(
                            BreakTime(
                                start = it,
                                end = it
                            )
                        )
                    ),
                    TimeRecord(
                        checkIn = it,
                        checkOut = it,
                        breakTimes = listOf(
                            BreakTime(
                                start = it,
                                end = it
                            )
                        )
                    ),
                    TimeRecord(
                        checkIn = it,
                        checkOut = it,
                        breakTimes = listOf(
                            BreakTime(
                                start = it,
                                end = it
                            )
                        )
                    )
                )
            )
        }
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val record = CalendarRecord(
            date = records[0].date,
            records = listOf(
                records[0].records[1],
                records[0].records[2].copy(
                    checkIn = formatter.parse("2025-12-01 12:00:00"),
                    checkOut = formatter.parse("2025-12-01 13:00:00")
                ),
                TimeRecord(
                    checkIn = formatter.parse("2025-12-01 17:00:00"),
                    checkOut = formatter.parse("2025-12-01 18:00:00"),
                    breakTimes = listOf(
                        BreakTime(
                            start = formatter.parse("2025-12-01 17:15:00"),
                            end = formatter.parse("2025-12-01 17:20:00")
                        ),
                        BreakTime(
                            start = formatter.parse("2025-12-01 17:45:00"),
                            end = formatter.parse("2025-12-01 17:50:00")
                        )
                    )
                )
            )
        )

        val network = FakeNetworkDataSource()
        val local = FakeLocalDataSource()
        val repository = DefaultCalendarRecordRepository(network, local)
        repository.updateRecord(records, record)

        assertEquals(1, network.inserted.count())
        assertEquals(record.records[2], network.inserted[0])
        assertEquals(1, network.updated.count())
        assertEquals(record.records[1], network.updated[0])
        assertEquals(1, network.deleted.count())
        assertEquals(records[0].records[0], network.deleted[0])

        assertEquals(2, local.insertedTimeRecords.count())
        assertEquals(record.records[2].id.reversed(), local.insertedTimeRecords[0].id)
        assertEquals(record.records[1].id, local.insertedTimeRecords[1].id)
        assertEquals(3, local.insertedBreakTimes.count())
        assertEquals(record.records[2].breakTimes[0].id.reversed(), local.insertedBreakTimes[0].id)
        assertEquals(record.records[2].breakTimes[1].id.reversed(), local.insertedBreakTimes[1].id)
        assertEquals(record.records[1].breakTimes[0].id, local.insertedBreakTimes[2].id)
        assertEquals(0, local.updatedTimeRecords.count())
        assertEquals(0, local.updatedBreakTimes.count())
        assertEquals(2, local.deletedTimeRecords.count())
        assertEquals(record.records[1].id, local.deletedTimeRecords[0].id)
        assertEquals(records[0].records[0].id, local.deletedTimeRecords[1].id)
        assertEquals(0, local.deletedBreakTimes.count())
    }
}

class FakeNetworkDataSource : NetworkDataSource {
    var getRecordsYear: Int = 0
    var getRecordsMonth: Int = 0
    override suspend fun getRecords(year: Int, month: Int): List<TimeRecord> {
        getRecordsYear = year
        getRecordsMonth = month
        return FakeLocalDataSource().records
    }

    val inserted = mutableListOf<TimeRecord>()
    override suspend fun insertRecord(record: TimeRecord): TimeRecord {
        inserted.add(record)
        val breakTimes = record.breakTimes.map { it.copy(id = it.id.reversed()) }
        return record.copy(id = record.id.reversed(), breakTimes = breakTimes)
    }

    val updated = mutableListOf<TimeRecord>()
    override suspend fun updateRecord(record: TimeRecord): TimeRecord {
        updated.add(record)
        return record
    }

    val deleted = mutableListOf<TimeRecord>()
    override suspend fun deleteRecord(record: TimeRecord) {
        deleted.add(record)
    }
}

class FakeLocalDataSource: LocalDataSource {
    private val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
    val records = listOf(
        TimeRecord(
            id = "1",
            checkIn = formatter.parse("2025-12-04 09:00:00"),
            checkOut = formatter.parse("2025-12-04 19:00:00"),
            breakTimes = listOf(
                BreakTime(
                    id = "1_1",
                    start = formatter.parse("2025-12-04 12:00:00"),
                    end = formatter.parse("2025-12-04 12:45:00")
                ),
                BreakTime(
                    id = "1_2",
                    start = formatter.parse("2025-12-04 17:30:00"),
                    end = formatter.parse("2025-12-04 18:00:00"),
                )
            )
        ),
        TimeRecord(
            id = "2",
            checkIn = formatter.parse("2025-12-04 22:00:00"),
            checkOut = formatter.parse("2025-12-05 01:00:00"),
            breakTimes = listOf(
                BreakTime(
                    id = "2_1",
                    start = formatter.parse("2025-12-04 23:00:00"),
                    end = formatter.parse("2025-12-05 00:30:00")
                )
            )
        ),
        TimeRecord(
            id = "3",
            checkIn = formatter.parse("2025-12-05 08:30:00"),
            checkOut = formatter.parse("2025-12-05 17:30:00"),
            breakTimes = listOf()
        )
    )

    override fun getRecords(year: Int, month: Int): Flow<Map<LocalTimeRecord, List<LocalBreakTime>>> {
        val records = mapOf(
            LocalTimeRecord(
                id = records[0].id,
                year = 2025,
                month = 12,
                checkIn = records[0].checkIn,
                checkOut = records[0].checkOut
            ) to listOf(
                LocalBreakTime(
                    id = records[0].breakTimes[0].id,
                    start = records[0].breakTimes[0].start,
                    end = records[0].breakTimes[0].end,
                    timeRecordId = records[0].id
                ),
                LocalBreakTime(
                    id = records[0].breakTimes[1].id,
                    start = records[0].breakTimes[1].start,
                    end = records[0].breakTimes[1].end,
                    timeRecordId = records[0].id
                )
            ),

            LocalTimeRecord(
                id = records[1].id,
                year = 2025,
                month = 12,
                checkIn = records[1].checkIn,
                checkOut = records[1].checkOut
            ) to listOf(
                LocalBreakTime(
                    id = records[1].breakTimes[0].id,
                    start = records[1].breakTimes[0].start,
                    end = records[1].breakTimes[0].end,
                    timeRecordId = records[1].id
                )
            ),

            LocalTimeRecord(
                id = records[2].id,
                year = 2025,
                month = 12,
                checkIn = records[2].checkIn,
                checkOut = records[2].checkOut
            ) to listOf()
        )

        return flowOf(records)
    }

    var deleteYear: Int = 0
    var deleteMonth: Int = 0
    override fun deleteRecords(year: Int, month: Int) {
        deleteYear = year
        deleteMonth = month
    }

    override fun getTimeRecords(): Flow<List<LocalTimeRecord>> { return flowOf() }
    override fun getBreakTimes(): Flow<List<LocalBreakTime>> { return flowOf() }

    val insertedTimeRecords = mutableListOf<LocalTimeRecord>()
    override suspend fun insert(record: LocalTimeRecord) {
        insertedTimeRecords.add(record)
    }

    val insertedBreakTimes = mutableListOf<LocalBreakTime>()
    override suspend fun insert(breakTime: LocalBreakTime) {
        insertedBreakTimes.add(breakTime)
    }

    val updatedTimeRecords = mutableListOf<LocalTimeRecord>()
    override suspend fun update(record: LocalTimeRecord) {
        updatedTimeRecords.add(record)
    }

    val updatedBreakTimes = mutableListOf<LocalBreakTime>()
    override suspend fun update(breakTime: LocalBreakTime) {
        updatedBreakTimes.add(breakTime)
    }

    val deletedTimeRecords = mutableListOf<LocalTimeRecord>()
    override suspend fun delete(record: LocalTimeRecord) {
        deletedTimeRecords.add(record)
    }

    val deletedBreakTimes = mutableListOf<LocalBreakTime>()
    override suspend fun delete(breakTime: LocalBreakTime) {
        deletedBreakTimes.add(breakTime)
    }
}
