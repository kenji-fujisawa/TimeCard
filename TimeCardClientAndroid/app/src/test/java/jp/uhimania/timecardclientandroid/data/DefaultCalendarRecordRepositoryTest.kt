package jp.uhimania.timecardclientandroid.data

import jp.uhimania.timecardclientandroid.data.source.NetworkDataSource
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

class DefaultCalendarRecordRepositoryTest {
    @Test
    fun testGetRecords() = runTest {
        val source = FakeNetworkDataSource()
        val repository = DefaultCalendarRecordRepository(source)
        val records = repository.getRecords(2025, 12)
        assertEquals(31, records.count())

        for (i in 0..<31) {
            assertEquals(2025, records[i].date.year())
            assertEquals(12, records[i].date.month())
            assertEquals(i + 1, records[i].date.day())

            when (i + 1) {
                4 -> {
                    assertEquals(2, records[i].records.count())
                    assertEquals(source.getRecords(2025, 12)[0], records[i].records[0])
                    assertEquals(source.getRecords(2025, 12)[1], records[i].records[1])
                }
                5 -> {
                    assertEquals(1, records[i].records.count())
                    assertEquals(source.getRecords(2025, 12)[2], records[i].records[0])
                }
                else -> {
                    assertEquals(0, records[i].records.count())
                }
            }
        }
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
                        breakTimes = listOf()
                    ),
                    TimeRecord(
                        checkIn = it,
                        checkOut = it,
                        breakTimes = listOf()
                    ),
                    TimeRecord(
                        checkIn = it,
                        checkOut = it,
                        breakTimes = listOf()
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
                    breakTimes = listOf()
                )
            )
        )

        val source = FakeNetworkDataSource()
        val repository = DefaultCalendarRecordRepository(source)
        val result = repository.updateRecord(records, record)

        assertEquals(1, source.inserted.count())
        assertEquals(record.records[2], source.inserted[0])
        assertEquals(1, source.updated.count())
        assertEquals(record.records[1], source.updated[0])
        assertEquals(1, source.deleted.count())
        assertEquals(records[0].records[0], source.deleted[0])

        assertEquals(record.date, result[0].date)
        assertEquals(3, result[0].records.count())
        assertEquals(record.records[0], result[0].records[0])
        assertEquals(record.records[1], result[0].records[1])
        assertNotEquals(record.records[2].id, result[0].records[2].id)
        assertEquals(record.records[2].checkIn, result[0].records[2].checkIn)
        assertEquals(record.records[2].checkOut, result[0].records[2].checkOut)
        assertEquals(record.records[2].breakTimes, result[0].records[2].breakTimes)
        for (i in 1..<31) {
            assertEquals(records[i], result[i])
        }
    }
}

class FakeNetworkDataSource : NetworkDataSource {
    val inserted = mutableListOf<TimeRecord>()
    val updated = mutableListOf<TimeRecord>()
    val deleted = mutableListOf<TimeRecord>()

    override suspend fun getRecords(year: Int, month: Int): List<TimeRecord> {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")

        val break1_1 = BreakTime(start = formatter.parse("2025-12-04 12:00:00") ?: Date(), end = formatter.parse("2025-12-04 12:45:00") ?: Date())
        val break1_2 = BreakTime(start = formatter.parse("2025-12-04 17:30:00") ?: Date(), end = formatter.parse("2025-12-04 18:00:00") ?: Date())
        val record1 = TimeRecord(checkIn = formatter.parse("2025-12-04 09:00:00") ?: Date(), checkOut = formatter.parse("2025-12-04 19:00:00") ?: Date(), breakTimes = listOf(break1_1, break1_2))

        val break2_1 = BreakTime(start = formatter.parse("2025-12-04 23:00:00") ?: Date(), end = formatter.parse("2025-12-05 00:30:00") ?: Date())
        val record2 = TimeRecord(checkIn = formatter.parse("2025-12-04 22:00:00") ?: Date(), checkOut = formatter.parse("2025-12-05 01:00:00") ?: Date(), breakTimes = listOf(break2_1))

        val record3 = TimeRecord(checkIn = formatter.parse("2025-12-05 08:30:00") ?: Date(), checkOut = formatter.parse("2025-12-05 17:30:00") ?: Date(), breakTimes = listOf())

        return listOf(record1, record2, record3)
    }

    @OptIn(ExperimentalUuidApi::class)
    override suspend fun insertRecord(record: TimeRecord): TimeRecord {
        inserted.add(record)
        return record.copy(id = Uuid.random().toString())
    }

    override suspend fun updateRecord(record: TimeRecord): TimeRecord {
        updated.add(record)
        return record
    }

    override suspend fun deleteRecord(record: TimeRecord) {
        deleted.add(record)
    }
}
