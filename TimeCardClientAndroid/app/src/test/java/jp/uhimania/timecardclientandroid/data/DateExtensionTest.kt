package jp.uhimania.timecardclientandroid.data

import org.junit.Assert.assertEquals
import org.junit.Test
import java.text.SimpleDateFormat

class DateExtensionTest {
    @Test
    fun testYearMonthDayHourMinuteSecond() {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val date = formatter.parse("2025-12-09 17:30:45")
        assertEquals(2025, date?.year())
        assertEquals(12, date?.month())
        assertEquals(9, date?.day())
        assertEquals(17, date?.hour())
        assertEquals(30, date?.minute())
        assertEquals(45, date?.second())
    }

    @Test
    fun testIsHoliday() {
        val formatter = SimpleDateFormat("yyyy-MM-dd")
        val date1 = formatter.parse("2025-12-10")
        assertEquals(false, date1?.isHoliday())

        val date2 = formatter.parse("2025-12-13")
        assertEquals(true, date2?.isHoliday())

        val date3 = formatter.parse("2025-12-14")
        assertEquals(true, date3?.isHoliday())

        val date4 = formatter.parse("2026-01-01")
        assertEquals(true, date4?.isHoliday())
    }
}