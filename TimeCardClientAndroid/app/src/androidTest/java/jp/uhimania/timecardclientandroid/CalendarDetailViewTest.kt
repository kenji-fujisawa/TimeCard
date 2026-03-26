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
import androidx.lifecycle.SavedStateHandle
import jp.uhimania.timecardclientandroid.data.BreakTime
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.TimeRecord
import jp.uhimania.timecardclientandroid.ui.CalendarDetailView
import jp.uhimania.timecardclientandroid.ui.CalendarDetailViewModel
import jp.uhimania.timecardclientandroid.ui.asTimeRecord
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
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

    inner class FakeCalendarRecordRepository : CalendarRecordRepository {
        override fun getRecordsStream(year: Int, month: Int): Flow<List<CalendarRecord>> {
            return flowOf()
        }

        override suspend fun getRecord(year: Int, month: Int, day: Int): CalendarRecord {
            return record
        }

        override suspend fun updateRecord(record: CalendarRecord) {}
    }

    @Test
    fun testCalendarDetailView() {
        val repository = FakeCalendarRecordRepository()
        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)
        composeTestRule.setContent {
            CalendarDetailView(
                onBack = {},
                viewModel = viewModel
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
        val repository = FakeCalendarRecordRepository()
        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)
        composeTestRule.setContent {
            CalendarDetailView(
                onBack = {},
                viewModel = viewModel
            )
        }

        composeTestRule.onRoot().performTouchInput {
            swipeUp(
                startY = 1000f,
                endY = 0f,
                durationMillis = 100
            )
        }
        composeTestRule.onNodeWithText("勤怠を追加").performClick()

        val result = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(3, result.count())
        assertEquals(record.records[0], result[0])
        assertEquals(record.records[1], result[1])
        assertEquals("2025-12-16 12:30:45", formatter.format(result[2].checkIn ?: Date()))
        assertEquals("2025-12-16 12:30:45", formatter.format(result[2].checkOut ?: Date()))
        assertEquals(0, result[2].breakTimes.count())
    }

    @Test
    fun testCalendarDetailView_addBreakTime() {
        val repository = FakeCalendarRecordRepository()
        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)
        composeTestRule.setContent {
            CalendarDetailView(
                onBack = {},
                viewModel = viewModel
            )
        }

        composeTestRule.onAllNodesWithText("休憩を追加")[0].performClick()

        val result1 = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result1.count())
        assertEquals(record.records[0].checkIn, result1[0].checkIn)
        assertEquals(record.records[0].checkOut, result1[0].checkOut)
        assertEquals(2, record.records[0].breakTimes.count())
        assertEquals(3, result1[0].breakTimes.count())
        assertEquals(record.records[0].breakTimes[0], result1[0].breakTimes[0])
        assertEquals(record.records[0].breakTimes[1], result1[0].breakTimes[1])
        assertEquals("2025-12-16 08:05:12", formatter.format(result1[0].breakTimes[2].start ?: Date()))
        assertEquals("2025-12-16 08:05:12", formatter.format(result1[0].breakTimes[2].end ?: Date()))
        assertEquals(record.records[1], result1[1])

        composeTestRule.onRoot().performTouchInput {
            swipeUp(
                startY = 1000f,
                endY = 0f,
                durationMillis = 100
            )
        }
        composeTestRule.onAllNodesWithText("休憩を追加")[1].performClick()

        val result2 = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result2.count())
        assertEquals(result1[0], result2[0])
        assertEquals(record.records[1].checkIn, result2[1].checkIn)
        assertEquals(record.records[1].checkOut, result2[1].checkOut)
        assertEquals(1, record.records[1].breakTimes.count())
        assertEquals(2, result2[1].breakTimes.count())
        assertEquals(record.records[1].breakTimes[0], result2[1].breakTimes[0])
        assertEquals("2025-12-16 22:30:18", formatter.format(result2[1].breakTimes[1].start ?: Date()))
        assertEquals("2025-12-16 22:30:18", formatter.format(result2[1].breakTimes[1].end ?: Date()))
    }

    @Test
    fun testCalendarDetailView_deleteTimeRecord() {
        val repository = FakeCalendarRecordRepository()
        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)
        composeTestRule.setContent {
            CalendarDetailView(
                onBack = {},
                viewModel = viewModel
            )
        }

        composeTestRule.onNodeWithText("Edit").performClick()

        composeTestRule.onNodeWithText("Done").assertExists()

        composeTestRule.onAllNodesWithContentDescription(Icons.Default.DoNotDisturbOn.name)[0].performClick()

        var result = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(1, result.count())
        assertEquals(record.records[1], result[0])

        composeTestRule.onAllNodesWithContentDescription(Icons.Default.DoNotDisturbOn.name)[0].performClick()

        result = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(0, result.count())
    }

    @Test
    fun testCalendarDetailView_deleteBreakTime() {
        val repository = FakeCalendarRecordRepository()
        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)
        composeTestRule.setContent {
            CalendarDetailView(
                onBack = {},
                viewModel = viewModel
            )
        }

        composeTestRule.onNodeWithText("Edit").performClick()

        composeTestRule.onNodeWithText("Done").assertExists()

        composeTestRule.onAllNodesWithContentDescription(Icons.Default.DoNotDisturbOn.name)[1].performClick()

        var result = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result.count())
        assertEquals(record.records[0].checkIn, result[0].checkIn)
        assertEquals(record.records[0].checkOut, result[0].checkOut)
        assertEquals(1, result[0].breakTimes.count())
        assertEquals(record.records[0].breakTimes[1], result[0].breakTimes[0])
        assertEquals(record.records[1], result[1])

        composeTestRule.onAllNodesWithContentDescription(Icons.Default.DoNotDisturbOn.name)[1].performClick()

        result = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result.count())
        assertEquals(record.records[0].checkIn, result[0].checkIn)
        assertEquals(record.records[0].checkOut, result[0].checkOut)
        assertEquals(0, result[0].breakTimes.count())
        assertEquals(record.records[1], result[1])

        composeTestRule.onRoot().performTouchInput {
            swipeUp()
        }
        composeTestRule.onAllNodesWithContentDescription(Icons.Default.DoNotDisturbOn.name)[2].performClick()

        result = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result.count())
        assertEquals(record.records[0].checkIn, result[0].checkIn)
        assertEquals(record.records[0].checkOut, result[0].checkOut)
        assertEquals(0, result[0].breakTimes.count())
        assertEquals(record.records[1].checkIn, result[1].checkIn)
        assertEquals(record.records[1].checkOut, result[1].checkOut)
        assertEquals(0, result[1].breakTimes.count())
    }

    @OptIn(ExperimentalTestApi::class)
    @Test
    fun testCalendarDetailView_editTimeRecord() {
        val repository = FakeCalendarRecordRepository()
        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)
        composeTestRule.setContent {
            CalendarDetailView(
                onBack = {},
                viewModel = viewModel
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

        var result = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result.count())
        assertEquals("2025-12-16 09:10:12", formatter.format(result[0].checkIn ?: Date()))
        assertEquals("2025-12-16 17:32:58", formatter.format(result[0].checkOut ?: Date()))
        assertEquals(record.records[0].breakTimes, result[0].breakTimes)
        assertEquals(record.records[1], result[1])

        composeTestRule.onNodeWithText("17:32")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("18 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("40 minutes"))
        composeTestRule.onNodeWithContentDescription("40 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        result = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result.count())
        assertEquals("2025-12-16 09:10:12", formatter.format(result[0].checkIn ?: Date()))
        assertEquals("2025-12-16 18:40:58", formatter.format(result[0].checkOut ?: Date()))
        assertEquals(record.records[0].breakTimes, result[0].breakTimes)
        assertEquals(record.records[1], result[1])

        composeTestRule.onNodeWithText("22:30")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("21 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("35 minutes"))
        composeTestRule.onNodeWithContentDescription("35 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        result = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result.count())
        assertEquals("2025-12-16 09:10:12", formatter.format(result[0].checkIn ?: Date()))
        assertEquals("2025-12-16 18:40:58", formatter.format(result[0].checkOut ?: Date()))
        assertEquals(record.records[0].breakTimes, result[0].breakTimes)
        assertEquals("2025-12-16 21:35:18", formatter.format(result[1].checkIn ?: Date()))
        assertEquals("2025-12-17 02:01:37", formatter.format(result[1].checkOut ?: Date()))
        assertEquals(record.records[1].breakTimes, result[1].breakTimes)

        composeTestRule.onNodeWithText("02:01")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("3 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("5 minutes"))
        composeTestRule.onNodeWithContentDescription("5 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        result = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result.count())
        assertEquals("2025-12-16 09:10:12", formatter.format(result[0].checkIn ?: Date()))
        assertEquals("2025-12-16 18:40:58", formatter.format(result[0].checkOut ?: Date()))
        assertEquals(record.records[0].breakTimes, result[0].breakTimes)
        assertEquals("2025-12-16 21:35:18", formatter.format(result[1].checkIn ?: Date()))
        assertEquals("2025-12-17 03:05:37", formatter.format(result[1].checkOut ?: Date()))
        assertEquals(record.records[1].breakTimes, result[1].breakTimes)
    }

    @OptIn(ExperimentalTestApi::class)
    @Test
    fun testCalendarDetailView_editBreakTime() {
        val repository = FakeCalendarRecordRepository()
        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)
        composeTestRule.setContent {
            CalendarDetailView(
                onBack = {},
                viewModel = viewModel
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

        val result1 = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result1.count())
        assertEquals(record.records[0].checkIn, result1[0].checkIn)
        assertEquals(record.records[0].checkOut, result1[0].checkOut)
        assertEquals("2025-12-16 11:50:34", formatter.format(result1[0].breakTimes[0].start ?: Date()))
        assertEquals("2025-12-16 12:48:22", formatter.format(result1[0].breakTimes[0].end ?: Date()))
        assertEquals(record.records[0].breakTimes[1], result1[0].breakTimes[1])
        assertEquals(record.records[1], result1[1])

        composeTestRule.onNodeWithText("12:48")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("13 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("10 minutes"))
        composeTestRule.onNodeWithContentDescription("10 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        val result2 = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result2.count())
        assertEquals(record.records[0].checkIn, result2[0].checkIn)
        assertEquals(record.records[0].checkOut, result2[0].checkOut)
        assertEquals("2025-12-16 11:50:34", formatter.format(result2[0].breakTimes[0].start ?: Date()))
        assertEquals("2025-12-16 13:10:22", formatter.format(result2[0].breakTimes[0].end ?: Date()))
        assertEquals(record.records[0].breakTimes[1], result2[0].breakTimes[1])
        assertEquals(record.records[1], result2[1])

        composeTestRule.onNodeWithText("15:03")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }
        composeTestRule.onNodeWithContentDescription("14 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("55 minutes"))
        composeTestRule.onNodeWithContentDescription("55 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        val result3 = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result3.count())
        assertEquals(record.records[0].checkIn, result3[0].checkIn)
        assertEquals(record.records[0].checkOut, result3[0].checkOut)
        assertEquals("2025-12-16 11:50:34", formatter.format(result3[0].breakTimes[0].start ?: Date()))
        assertEquals("2025-12-16 13:10:22", formatter.format(result3[0].breakTimes[0].end ?: Date()))
        assertEquals("2025-12-16 14:55:42", formatter.format(result3[0].breakTimes[1].start ?: Date()))
        assertEquals("2025-12-16 15:18:04", formatter.format(result3[0].breakTimes[1].end ?: Date()))
        assertEquals(record.records[1], result3[1])

        composeTestRule.onRoot().performTouchInput {
            swipeUp(
                startY = 1000f,
                endY = 0f,
                durationMillis = 100
            )
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

        val result4 = viewModel.uiState.value.records.map { it.asTimeRecord() }

        assertEquals(2, record.records.count())
        assertEquals(2, result4.count())
        assertEquals(result3[0], result4[0])
        assertEquals(record.records[1].checkIn, result4[1].checkIn)
        assertEquals(record.records[1].checkOut, result4[1].checkOut)
        assertEquals("2025-12-16 23:48:56", formatter.format(result4[1].breakTimes[0].start ?: Date()))
        assertEquals("2025-12-17 01:15:39", formatter.format(result4[1].breakTimes[0].end ?: Date()))
    }

    @Test
    fun testCalendarDetailView_back() {
        var backed = false
        composeTestRule.setContent {
            CalendarDetailView(
                onBack = { backed = true }
            )
        }

        composeTestRule.onNodeWithContentDescription(Icons.AutoMirrored.Filled.ArrowBack.name).performClick()

        assertEquals(true, backed)
    }
}