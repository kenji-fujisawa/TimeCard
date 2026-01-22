package jp.uhimania.timecardclientandroid

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.DoNotDisturbOn
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeUp
import jp.uhimania.timecardclientandroid.data.BreakTime
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.TimeRecord
import jp.uhimania.timecardclientandroid.ui.CalendarDetailView
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Date

class CalendarDetailViewTest {
    @get:Rule
    val composeTestRule = createComposeRule()

    val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
    val record = CalendarRecord(
        date = formatter.parse("2025-12-16 12:30:45") ?: Date(),
        records = listOf(
            TimeRecord(
                checkIn = formatter.parse("2025-12-16 08:05:12"),
                checkOut = formatter.parse("2025-12-16 17:32:58"),
                breakTimes = listOf(
                    BreakTime(
                        start = formatter.parse("2025-12-16 12:15:34"),
                        end = formatter.parse("2025-12-16 12:48:22")
                    ),
                    BreakTime(
                        start = formatter.parse("2025-12-16 15:03:42"),
                        end = formatter.parse("2025-12-16 15:18:04")
                    )
                )
            ),
            TimeRecord(
                checkIn = formatter.parse("2025-12-16 22:30:18"),
                checkOut = formatter.parse("2025-12-17 02:01:37"),
                breakTimes = listOf(
                    BreakTime(
                        start = formatter.parse("2025-12-16 23:48:56"),
                        end = formatter.parse("2025-12-17 00:27:39")
                    )
                )
            )
        )
    )

    @Test
    fun testCalendarDetailView() {
        composeTestRule.setContent {
            CalendarDetailView(
                record = record,
                onRecordChange = {},
                onBack = {}
            )
        }

        composeTestRule.onNodeWithText("12月16日(Tue)").assertExists()
        composeTestRule.onAllNodesWithText("2025-12-16").assertCountEquals(8)
        composeTestRule.onAllNodesWithText("2025-12-17").assertCountEquals(2)
        composeTestRule.onNodeWithText("08:05").assertExists()
        composeTestRule.onNodeWithText("17:32").assertExists()
        composeTestRule.onNodeWithText("12:15").assertExists()
        composeTestRule.onNodeWithText("12:48").assertExists()
        composeTestRule.onNodeWithText("15:03").assertExists()
        composeTestRule.onNodeWithText("15:18").assertExists()
        composeTestRule.onNodeWithText("22:30").assertExists()
        composeTestRule.onNodeWithText("02:01").assertExists()
        composeTestRule.onNodeWithText("23:48").assertExists()
        composeTestRule.onNodeWithText("00:27").assertExists()
    }

    @Test
    fun testCalendarDetailView_addTimeRecord() {
        var result: CalendarRecord? = null
        composeTestRule.setContent {
            CalendarDetailView(
                record = record,
                onRecordChange = { result = it },
                onBack = {}
            )
        }

        composeTestRule.onRoot().performTouchInput {
            swipeUp()
        }
        composeTestRule.onNodeWithText("勤怠を追加").performClick()

        assertEquals(2, record.records.count())
        assertEquals(3, result?.records?.count())
        assertEquals(record.records[0], result?.records[0])
        assertEquals(record.records[1], result?.records[1])
        assertEquals("2025-12-16 12:30:45", formatter.format(result?.records[2]?.checkIn ?: Date()))
        assertEquals("2025-12-16 12:30:45", formatter.format(result?.records[2]?.checkOut ?: Date()))
        assertEquals(0, result?.records[2]?.breakTimes?.count())
    }

    @Test
    fun testCalendarDetailView_addBreakTime() {
        var result: CalendarRecord? = null
        composeTestRule.setContent {
            CalendarDetailView(
                record = record,
                onRecordChange = { result = it },
                onBack = {}
            )
        }

        composeTestRule.onAllNodesWithText("休憩を追加")[0].performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0].checkIn, result?.records[0]?.checkIn)
        assertEquals(record.records[0].checkOut, result?.records[0]?.checkOut)
        assertEquals(3, result?.records[0]?.breakTimes?.count())
        assertEquals(record.records[0].breakTimes[0], result?.records[0]?.breakTimes[0])
        assertEquals(record.records[0].breakTimes[1], result?.records[0]?.breakTimes[1])
        assertEquals("2025-12-16 08:05:12", formatter.format(result?.records[0]?.breakTimes[2]?.start ?: Date()))
        assertEquals("2025-12-16 08:05:12", formatter.format(result?.records[0]?.breakTimes[2]?.end ?: Date()))
        assertEquals(record.records[1], result?.records[1])

        composeTestRule.onRoot().performTouchInput {
            swipeUp()
        }
        composeTestRule.onAllNodesWithText("休憩を追加")[1].performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0], result?.records[0])
        assertEquals(record.records[1].checkIn, result?.records[1]?.checkIn)
        assertEquals(record.records[1].checkOut, result?.records[1]?.checkOut)
        assertEquals(2, result?.records[1]?.breakTimes?.count())
        assertEquals(record.records[1].breakTimes[0], result?.records[1]?.breakTimes[0])
        assertEquals("2025-12-16 22:30:18", formatter.format(result?.records[1]?.breakTimes[1]?.start ?: Date()))
        assertEquals("2025-12-16 22:30:18", formatter.format(result?.records[1]?.breakTimes[1]?.end ?: Date()))
    }

    @Test
    fun testCalendarDetailView_deleteTimeRecord() {
        var result: CalendarRecord? = null
        composeTestRule.setContent {
            CalendarDetailView(
                record = record,
                onRecordChange = { result = it },
                onBack = {}
            )
        }

        composeTestRule.onNodeWithText("Edit").performClick()

        composeTestRule.onNodeWithText("Done").assertExists()

        composeTestRule.onAllNodesWithContentDescription(Icons.Default.DoNotDisturbOn.name)[0].performClick()

        assertEquals(2, record.records.count())
        assertEquals(1, result?.records?.count())
        assertEquals(record.records[1], result?.records[0])

        composeTestRule.onAllNodesWithContentDescription(Icons.Default.DoNotDisturbOn.name)[3].performClick()

        assertEquals(2, record.records.count())
        assertEquals(1, result?.records?.count())
        assertEquals(record.records[0], result?.records[0])
    }

    @Test
    fun testCalendarDetailView_deleteBreakTime() {
        var result: CalendarRecord? = null
        composeTestRule.setContent {
            CalendarDetailView(
                record = record,
                onRecordChange = { result = it },
                onBack = {}
            )
        }

        composeTestRule.onNodeWithText("Edit").performClick()

        composeTestRule.onNodeWithText("Done").assertExists()

        composeTestRule.onAllNodesWithContentDescription(Icons.Default.DoNotDisturbOn.name)[1].performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0].checkIn, result?.records[0]?.checkIn)
        assertEquals(record.records[0].checkOut, result?.records[0]?.checkOut)
        assertEquals(1, result?.records[0]?.breakTimes?.count())
        assertEquals(record.records[0].breakTimes[1], result?.records[0]?.breakTimes[0])
        assertEquals(record.records[1], result?.records[1])

        composeTestRule.onAllNodesWithContentDescription(Icons.Default.DoNotDisturbOn.name)[2].performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0].checkIn, result?.records[0]?.checkIn)
        assertEquals(record.records[0].checkOut, result?.records[0]?.checkOut)
        assertEquals(1, result?.records[0]?.breakTimes?.count())
        assertEquals(record.records[0].breakTimes[0], result?.records[0]?.breakTimes[0])
        assertEquals(record.records[1], result?.records[1])

        composeTestRule.onRoot().performTouchInput {
            swipeUp()
        }
        composeTestRule.onAllNodesWithContentDescription(Icons.Default.DoNotDisturbOn.name)[4].performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0], result?.records[0])
        assertEquals(record.records[1].checkIn, result?.records[1]?.checkIn)
        assertEquals(record.records[1].checkOut, result?.records[1]?.checkOut)
        assertEquals(0, result?.records[1]?.breakTimes?.count())
    }

    @OptIn(ExperimentalTestApi::class)
    @Test
    fun testCalendarDetailView_editTimeRecord() {
        var result: CalendarRecord? = null
        composeTestRule.setContent {
            CalendarDetailView(
                record = record,
                onRecordChange = { result = it },
                onBack = {}
            )
        }

        composeTestRule.onNodeWithText("08:05")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("9 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("10 minutes"))
        composeTestRule.onNodeWithContentDescription("10 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals("2025-12-16 09:10:12", formatter.format(result?.records[0]?.checkIn ?: Date()))
        assertEquals("2025-12-16 17:32:58", formatter.format(result?.records[0]?.checkOut ?: Date()))
        assertEquals(record.records[0].breakTimes, result?.records[0]?.breakTimes)
        assertEquals(record.records[1], result?.records[1])

        composeTestRule.onNodeWithText("17:32")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("18 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("40 minutes"))
        composeTestRule.onNodeWithContentDescription("40 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals("2025-12-16 08:05:12", formatter.format(result?.records[0]?.checkIn ?: Date()))
        assertEquals("2025-12-16 18:40:58", formatter.format(result?.records[0]?.checkOut ?: Date()))
        assertEquals(record.records[0].breakTimes, result?.records[0]?.breakTimes)
        assertEquals(record.records[1], result?.records[1])

        composeTestRule.onNodeWithText("22:30")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("21 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("35 minutes"))
        composeTestRule.onNodeWithContentDescription("35 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0], result?.records[0])
        assertEquals("2025-12-16 21:35:18", formatter.format(result?.records[1]?.checkIn ?: Date()))
        assertEquals("2025-12-17 02:01:37", formatter.format(result?.records[1]?.checkOut ?: Date()))
        assertEquals(record.records[1].breakTimes, result?.records[1]?.breakTimes)

        composeTestRule.onNodeWithText("02:01")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("3 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("5 minutes"))
        composeTestRule.onNodeWithContentDescription("5 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0], result?.records[0])
        assertEquals("2025-12-16 22:30:18", formatter.format(result?.records[1]?.checkIn ?: Date()))
        assertEquals("2025-12-17 03:05:37", formatter.format(result?.records[1]?.checkOut ?: Date()))
        assertEquals(record.records[1].breakTimes, result?.records[1]?.breakTimes)
    }

    @OptIn(ExperimentalTestApi::class)
    @Test
    fun testCalendarDetailView_editBreakTime() {
        var result: CalendarRecord? = null
        composeTestRule.setContent {
            CalendarDetailView(
                record = record,
                onRecordChange = { result = it },
                onBack = {}
            )
        }

        composeTestRule.onNodeWithText("12:15")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("11 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("50 minutes"))
        composeTestRule.onNodeWithContentDescription("50 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0].checkIn, result?.records[0]?.checkIn)
        assertEquals(record.records[0].checkOut, result?.records[0]?.checkOut)
        assertEquals("2025-12-16 11:50:34", formatter.format(result?.records[0]?.breakTimes[0]?.start ?: Date()))
        assertEquals("2025-12-16 12:48:22", formatter.format(result?.records[0]?.breakTimes[0]?.end ?: Date()))
        assertEquals(record.records[0].breakTimes[1], result?.records[0]?.breakTimes[1])
        assertEquals(record.records[1], result?.records[1])

        composeTestRule.onNodeWithText("12:48")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("13 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("10 minutes"))
        composeTestRule.onNodeWithContentDescription("10 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0].checkIn, result?.records[0]?.checkIn)
        assertEquals(record.records[0].checkOut, result?.records[0]?.checkOut)
        assertEquals("2025-12-16 12:15:34", formatter.format(result?.records[0]?.breakTimes[0]?.start ?: Date()))
        assertEquals("2025-12-16 13:10:22", formatter.format(result?.records[0]?.breakTimes[0]?.end ?: Date()))
        assertEquals(record.records[0].breakTimes[1], result?.records[0]?.breakTimes[1])
        assertEquals(record.records[1], result?.records[1])

        composeTestRule.onNodeWithText("15:03")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("14 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("55 minutes"))
        composeTestRule.onNodeWithContentDescription("55 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0].checkIn, result?.records[0]?.checkIn)
        assertEquals(record.records[0].checkOut, result?.records[0]?.checkOut)
        assertEquals(record.records[0].breakTimes[0], result?.records[0]?.breakTimes[0])
        assertEquals("2025-12-16 14:55:42", formatter.format(result?.records[0]?.breakTimes[1]?.start ?: Date()))
        assertEquals("2025-12-16 15:18:04", formatter.format(result?.records[0]?.breakTimes[1]?.end ?: Date()))
        assertEquals(record.records[1], result?.records[1])

        composeTestRule.onRoot().performTouchInput {
            swipeUp()
        }
        composeTestRule.onNodeWithText("00:27")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("1 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("15 minutes"))
        composeTestRule.onNodeWithContentDescription("15 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        assertEquals(2, record.records.count())
        assertEquals(2, result?.records?.count())
        assertEquals(record.records[0], result?.records[0])
        assertEquals(record.records[1].checkIn, result?.records[1]?.checkIn)
        assertEquals(record.records[1].checkOut, result?.records[1]?.checkOut)
        assertEquals("2025-12-16 23:48:56", formatter.format(result?.records[1]?.breakTimes[0]?.start ?: Date()))
        assertEquals("2025-12-17 01:15:39", formatter.format(result?.records[1]?.breakTimes[0]?.end ?: Date()))
    }

    @Test
    fun testCalendarDetailView_back() {
        var backed = false
        composeTestRule.setContent {
            CalendarDetailView(
                record = record,
                onRecordChange = {},
                onBack = { backed = true }
            )
        }

        composeTestRule.onNodeWithContentDescription(Icons.AutoMirrored.Filled.ArrowBack.name).performClick()

        assertEquals(true, backed)
    }
}