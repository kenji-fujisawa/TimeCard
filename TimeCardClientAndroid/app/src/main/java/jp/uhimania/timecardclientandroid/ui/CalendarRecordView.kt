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
import jp.uhimania.timecardclientandroid.data.BreakTime
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.TimeRecord
import jp.uhimania.timecardclientandroid.data.isHoliday
import jp.uhimania.timecardclientandroid.data.startOfDay
import jp.uhimania.timecardclientandroid.data.timeIntervalSince
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import java.text.SimpleDateFormat
import java.util.Date

@Composable
fun CalendarRecordView(
    record: CalendarRecord,
    modifier: Modifier = Modifier
) {
    val formatter = SimpleDateFormat(stringResource(R.string.format_hour_minute))

    Row(
        modifier = modifier.padding(dimensionResource(R.dimen.padding_small))
    ) {
        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            val formatter = SimpleDateFormat(stringResource(R.string.format_day))
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
                val from = record.checkIn?.startOfDay()
                val elapsed = record.checkOut?.timeIntervalSince(from ?: Date())
                Text(elapsed?.format() ?: "")
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
                    val from = breakTime.start?.startOfDay()
                    val elapsed = breakTime.end?.timeIntervalSince(from ?: Date())
                    Text(elapsed?.format() ?: "")
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun CalendarRecordPreview() {
    TimeCardClientAndroidTheme {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val break1 = BreakTime(start = formatter.parse("2025-12-04 12:00:00") ?: Date(), end = formatter.parse("2025-12-04 12:45:00") ?: Date())
        val break2 = BreakTime(start = formatter.parse("2025-12-04 17:30:00") ?: Date(), end = formatter.parse("2025-12-04 18:00:00") ?: Date())
        val record1 = TimeRecord(checkIn = formatter.parse("2025-12-04 09:00:00") ?: Date(), checkOut = formatter.parse("2025-12-04 19:00:00") ?: Date(), breakTimes = listOf(break1, break2))
        val break3 = BreakTime(start = formatter.parse("2025-12-04 23:00:00") ?: Date(), end = formatter.parse("2025-12-05 00:30:00") ?: Date())
        val record2 = TimeRecord(checkIn = formatter.parse("2025-12-04 22:00:00") ?: Date(), checkOut = formatter.parse("2025-12-05 01:00:00") ?: Date(), breakTimes = listOf(break3))
        CalendarRecordView(CalendarRecord(date = formatter.parse("2025-12-04 00:00:00") ?: Date(), records = listOf(record1, record2)))
    }
}

@Preview(showBackground = true)
@Composable
private fun CalendarRecordPreviewSingleLine() {
    TimeCardClientAndroidTheme {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        val break1 = BreakTime(start = formatter.parse("2025-12-07 12:00:00") ?: Date(), end = formatter.parse("2025-12-07 12:45:00") ?: Date())
        val record1 = TimeRecord(checkIn = formatter.parse("2025-12-07 09:00:00") ?: Date(), checkOut = formatter.parse("2025-12-07 19:00:00") ?: Date(), breakTimes = listOf(break1))
        CalendarRecordView(CalendarRecord(date = formatter.parse("2025-12-07 00:00:00") ?: Date(), records = listOf(record1)))
    }
}
