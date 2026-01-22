package jp.uhimania.timecardclientandroid.data

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar

class CalendarExtensionTest {
    @Test
    fun testDatesOf() {
        assertEquals(31, Calendar.getInstance().datesOf(2025, 12).count())
        assertEquals(28, Calendar.getInstance().datesOf(2025, 2).count())
        assertEquals(29, Calendar.getInstance().datesOf(2024, 2).count())

        val dates = Calendar.getInstance().datesOf(2025, 12)
        for (i in 0..<31) {
            assertEquals(2025, dates[i].year())
            assertEquals(12, dates[i].month())
            assertEquals(i + 1, dates[i].day())
            assertEquals(0, dates[i].hour())
            assertEquals(0, dates[i].minute())
            assertEquals(0, dates[i].second())
        }
    }
}