package jp.uhimania.timecardclientandroid.data

import jp.uhimania.timecardclientandroid.data.source.NetworkDataSource
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Date

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
}

class FakeNetworkDataSource : NetworkDataSource {
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
}
