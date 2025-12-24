package jp.uhimania.timecardclientandroid

import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import jp.uhimania.timecardclientandroid.data.BreakTime
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.TimeRecord
import jp.uhimania.timecardclientandroid.ui.CalendarRecordView
import org.junit.Rule
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Date

class CalendarRecordTest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun testCalendarRecordView() {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val break1 = BreakTime(start = formatter.parse("2025-12-04 12:00:00") ?: Date(), end = formatter.parse("2025-12-04 12:45:00") ?: Date())
        val break2 = BreakTime(start = formatter.parse("2025-12-04 17:30:00") ?: Date(), end = formatter.parse("2025-12-04 18:00:00") ?: Date())
        val record1 = TimeRecord(checkIn = formatter.parse("2025-12-04 09:00:00") ?: Date(), checkOut = formatter.parse("2025-12-04 19:00:00") ?: Date(), breakTimes = listOf(break1, break2))
        val break3 = BreakTime(start = formatter.parse("2025-12-04 23:00:00") ?: Date(), end = formatter.parse("2025-12-05 00:30:00") ?: Date())
        val record2 = TimeRecord(checkIn = formatter.parse("2025-12-04 22:00:00") ?: Date(), checkOut = formatter.parse("2025-12-05 01:00:00") ?: Date(), breakTimes = listOf(break3))
        val record = CalendarRecord(date = formatter.parse("2025-12-04 00:00:00") ?: Date(), records = listOf(record1, record2))

        composeTestRule.setContent {
            CalendarRecordView(record)
        }

        composeTestRule.onNodeWithText("04(Thu)").assertExists()
        composeTestRule.onNodeWithText("09:00").assertExists()
        composeTestRule.onNodeWithText("12:00").assertExists()
        composeTestRule.onNodeWithText("12:45").assertExists()
        composeTestRule.onNodeWithText("17:30").assertExists()
        composeTestRule.onNodeWithText("18:00").assertExists()
        composeTestRule.onNodeWithText("19:00").assertExists()
        composeTestRule.onNodeWithText("22:00").assertExists()
        composeTestRule.onNodeWithText("23:00").assertExists()
        composeTestRule.onNodeWithText("24:30").assertExists()
        composeTestRule.onNodeWithText("25:00").assertExists()
    }
}