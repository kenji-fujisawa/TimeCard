package jp.uhimania.timecardclientandroid

import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import jp.uhimania.timecardclientandroid.data.TimeInterval
import jp.uhimania.timecardclientandroid.ui.CalendarRecordScreen
import jp.uhimania.timecardclientandroid.ui.CalendarUiState
import org.junit.Rule
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Date

class CalendarRecordScreenTest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun testCalendarRecordView() {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val break1 = CalendarUiState.BreakTime(start = formatter.parse("2025-12-04 12:00:00") ?: Date(), end = formatter.parse("2025-12-04 12:45:00") ?: Date(), elapsed = TimeInterval(12 * 60 * 60 + 45 * 60))
        val break2 = CalendarUiState.BreakTime(start = formatter.parse("2025-12-04 17:30:00") ?: Date(), end = formatter.parse("2025-12-04 18:00:00") ?: Date(), elapsed = TimeInterval(18 * 60 * 60))
        val record1 = CalendarUiState.TimeRecord(checkIn = formatter.parse("2025-12-04 09:00:00") ?: Date(), checkOut = formatter.parse("2025-12-04 19:00:00") ?: Date(), elapsed = TimeInterval(19 * 60 * 60), breakTimes = listOf(break1, break2))
        val break3 = CalendarUiState.BreakTime(start = formatter.parse("2025-12-04 23:00:00") ?: Date(), end = formatter.parse("2025-12-05 00:30:00") ?: Date(), elapsed = TimeInterval(24 * 60 * 60 + 30 * 60))
        val record2 = CalendarUiState.TimeRecord(checkIn = formatter.parse("2025-12-04 22:00:00") ?: Date(), checkOut = formatter.parse("2025-12-05 01:00:00") ?: Date(), elapsed = TimeInterval(25 * 60 * 60), breakTimes = listOf(break3))
        val record = CalendarUiState.CalendarRecord(date = formatter.parse("2025-12-04 00:00:00") ?: Date(), records = listOf(record1, record2))

        composeTestRule.setContent {
            CalendarRecordScreen(record)
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