package jp.uhimania.timecardclientandroid

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import jp.uhimania.timecardclientandroid.ui.MonthSelector
import org.junit.Rule
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Date

class MonthSelectorTest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun testMonthSelector() {
        val formatter = SimpleDateFormat("yyyy-MM-dd")
        var date by mutableStateOf(formatter.parse("2025-12-04") ?: Date())

        composeTestRule.setContent {
            MonthSelector(
                date = date,
                onDateChange = { date = it },
                formatter = "yyyy-MM"
            )
        }

        composeTestRule.onNodeWithText("2025-12").assertExists()

        val next = composeTestRule.onNodeWithContentDescription(Icons.AutoMirrored.Filled.KeyboardArrowRight.name)
        next.performClick()
        composeTestRule.onNodeWithText("2026-01").assertExists()

        val prev = composeTestRule.onNodeWithContentDescription(Icons.AutoMirrored.Filled.KeyboardArrowLeft.name)
        prev.performClick()
        prev.performClick()
        composeTestRule.onNodeWithText("2025-11").assertExists()
    }
}