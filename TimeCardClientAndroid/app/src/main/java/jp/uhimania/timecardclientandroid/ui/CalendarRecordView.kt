package jp.uhimania.timecardclientandroid.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import jp.uhimania.timecardclientandroid.R
import jp.uhimania.timecardclientandroid.data.TimeInterval
import jp.uhimania.timecardclientandroid.data.isHoliday
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun CalendarRecordView(
    record: CalendarUiState.CalendarRecord,
    modifier: Modifier = Modifier
) {
    val formatter = SimpleDateFormat(stringResource(R.string.format_hour_minute), Locale.getDefault())

    Row(
        modifier = modifier.padding(dimensionResource(R.dimen.padding_small))
    ) {
        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            val formatter = SimpleDateFormat(stringResource(R.string.format_day), Locale.getDefault())
            val style = MaterialTheme.typography.bodyLarge
            Text(
                text = formatter.format(record.date),
                style = if (record.date.isHoliday()) style.copy(color = Color.Red) else style
            )
        }

        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            record.records.forEach { record ->
                val date = record.checkIn?.let { formatter.format(it) } ?: ""
                Text(date)
            }
        }

        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            record.records.forEach { record ->
                Text(record.elapsed?.format() ?: "")
            }
        }

        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            record.records.forEach { record ->
                record.breakTimes.forEach { breakTime ->
                    val date = breakTime.start?.let { formatter.format(it) } ?: ""
                    Text(date)
                }
            }
        }

        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            record.records.forEach { record ->
                record.breakTimes.forEach { breakTime ->
                    Text(breakTime.elapsed?.format() ?: "")
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun CalendarRecordPreview() {
    TimeCardClientAndroidTheme {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        val break1 = CalendarUiState.BreakTime(start = formatter.parse("2025-12-04 12:00:00") ?: Date(), end = formatter.parse("2025-12-04 12:45:00") ?: Date(), elapsed = TimeInterval(12 * 60 * 60 + 45 * 60))
        val break2 = CalendarUiState.BreakTime(start = formatter.parse("2025-12-04 17:30:00") ?: Date(), end = formatter.parse("2025-12-04 18:00:00") ?: Date(), elapsed = TimeInterval(18 * 60 * 60))
        val record1 = CalendarUiState.TimeRecord(checkIn = formatter.parse("2025-12-04 09:00:00") ?: Date(), checkOut = formatter.parse("2025-12-04 19:00:00") ?: Date(), elapsed = TimeInterval(19 * 60 * 60), breakTimes = listOf(break1, break2))
        val break3 = CalendarUiState.BreakTime(start = formatter.parse("2025-12-04 23:00:00") ?: Date(), end = formatter.parse("2025-12-05 00:30:00") ?: Date(), elapsed = TimeInterval(24 * 60 * 60 + 30 * 60))
        val record2 = CalendarUiState.TimeRecord(checkIn = formatter.parse("2025-12-04 22:00:00") ?: Date(), checkOut = formatter.parse("2025-12-05 01:00:00") ?: Date(), elapsed = TimeInterval(25 * 60 * 60), breakTimes = listOf(break3))
        CalendarRecordView(CalendarUiState.CalendarRecord(date = formatter.parse("2025-12-04 00:00:00") ?: Date(), records = listOf(record1, record2)))
    }
}

@Preview(showBackground = true)
@Composable
private fun CalendarRecordPreviewSingleLine() {
    TimeCardClientAndroidTheme {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        val break1 = CalendarUiState.BreakTime(start = formatter.parse("2025-12-07 12:00:00") ?: Date(), end = formatter.parse("2025-12-07 12:45:00") ?: Date(), elapsed = TimeInterval(12 * 60 * 60 + 45 * 60))
        val record1 = CalendarUiState.TimeRecord(checkIn = formatter.parse("2025-12-07 09:00:00") ?: Date(), checkOut = formatter.parse("2025-12-07 19:00:00") ?: Date(), elapsed = TimeInterval(19 * 60 * 60), breakTimes = listOf(break1))
        CalendarRecordView(CalendarUiState.CalendarRecord(date = formatter.parse("2025-12-07 00:00:00") ?: Date(), records = listOf(record1)))
    }
}
