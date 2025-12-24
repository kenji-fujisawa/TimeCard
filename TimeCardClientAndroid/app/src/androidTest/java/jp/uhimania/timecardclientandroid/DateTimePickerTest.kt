package jp.uhimania.timecardclientandroid

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import jp.uhimania.timecardclientandroid.ui.DateTimePicker
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Date

class DateTimePickerTest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun testDateTimePicker() {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val date = formatter.parse("2025-12-15 12:30:45") ?: Date()

        composeTestRule.setContent {
            DateTimePicker(
                label = "test label",
                date = date,
                onDateChange = {}
            )
        }

        composeTestRule.onNodeWithText("test label").assertExists()
        composeTestRule.onNodeWithText("2025-12-15").assertExists()
        composeTestRule.onNodeWithText("12:30").assertExists()
    }

    @Test
    fun testDateTimePicker_showDateDialog() {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val date = formatter.parse("2025-12-15 12:30:45") ?: Date()

        composeTestRule.setContent {
            DateTimePicker(
                label = "test label",
                date = date,
                onDateChange = {}
            )
        }

        composeTestRule.onNodeWithText("2025-12-15")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }

        composeTestRule.onNodeWithText("OK").assertExists()
        composeTestRule.onNodeWithText("Cancel").assertExists()

        composeTestRule.onNodeWithText("Cancel").performClick()

        composeTestRule.onNodeWithText("OK").assertDoesNotExist()
        composeTestRule.onNodeWithText("Cancel").assertDoesNotExist()
    }

    @Test
    fun testDateTimePicker_showTimeDialog() {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val date = formatter.parse("2025-12-15 12:30:45") ?: Date()

        composeTestRule.setContent {
            DateTimePicker(
                label = "test label",
                date = date,
                onDateChange = {}
            )
        }

        composeTestRule.onNodeWithText("12:30")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }

        composeTestRule.onNodeWithText("OK").assertExists()
        composeTestRule.onNodeWithText("Cancel").assertExists()

        composeTestRule.onNodeWithText("Cancel").performClick()

        composeTestRule.onNodeWithText("OK").assertDoesNotExist()
        composeTestRule.onNodeWithText("Cancel").assertDoesNotExist()
    }

    @Test
    fun testDateTimePicker_onDateChange() {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val date = formatter.parse("2025-12-15 12:30:45") ?: Date()
        var result = Date()

        composeTestRule.setContent {
            DateTimePicker(
                label = "test label",
                date = date,
                onDateChange = { result = it }
            )
        }

        composeTestRule.onNodeWithText("2025-12-15")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }

        composeTestRule.onNodeWithText("Wednesday, December 31, 2025").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        composeTestRule.onNodeWithText("OK").assertDoesNotExist()
        composeTestRule.onNodeWithText("Cancel").assertDoesNotExist()

        assertEquals("2025-12-31 12:30:45", formatter.format(result))
        assertEquals("2025-12-15 12:30:45", formatter.format(date))
    }

    @OptIn(ExperimentalTestApi::class)
    @Test
    fun testDateTimePicker_onTimeChange() {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val date = formatter.parse("2025-12-15 12:30:45") ?: Date()
        var result = Date()

        composeTestRule.setContent {
            DateTimePicker(
                label = "test label",
                date = date,
                onDateChange = { result = it }
            )
        }

        composeTestRule.onNodeWithText("12:30")
            .performTouchInput {
                down(percentOffset(.5f, .5f))
                up()
            }

        composeTestRule.onNodeWithContentDescription("23 hours").performClick()
        composeTestRule.waitUntilAtLeastOneExists(hasContentDescription("5 minutes"))
        composeTestRule.onNodeWithContentDescription("5 minutes").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        composeTestRule.onNodeWithText("OK").assertDoesNotExist()
        composeTestRule.onNodeWithText("Cancel").assertDoesNotExist()

        assertEquals("2025-12-15 23:05:45", formatter.format(result))
        assertEquals("2025-12-15 12:30:45", formatter.format(date))
    }
}