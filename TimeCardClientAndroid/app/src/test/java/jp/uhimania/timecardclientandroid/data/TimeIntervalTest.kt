package jp.uhimania.timecardclientandroid.data

import org.junit.Assert.assertEquals
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Date

class TimeIntervalTest {
    @Test
    fun testFormat() {
        assertEquals("00:00", TimeInterval(10).format())
        assertEquals("00:01", TimeInterval(60).format())
        assertEquals("00:30", TimeInterval(30 * 60 + 45).format())
        assertEquals("01:05", TimeInterval(1 * 60 * 60 + 5 * 60).format())
        assertEquals("25:45", TimeInterval(25 * 60 * 60 + 45 * 60).format())
    }

    @Test
    fun testTimeIntervalSince() {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val from = formatter.parse("2025-12-05 12:00:00") ?: Date()
        val to = formatter.parse("2025-12-06 15:45:32") ?: Date()
        val interval = to.timeIntervalSince(from)
        assertEquals(24 * 60 * 60 + 3 * 60 * 60 + 45 * 60 + 32, interval.value)
    }

    @Test
    fun testStartOfDay() {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val date = formatter.parse("2025-12-05 12:30:45") ?: Date()
        assertEquals("2025-12-05 00:00:00", formatter.format(date.startOfDay()))
    }
}
