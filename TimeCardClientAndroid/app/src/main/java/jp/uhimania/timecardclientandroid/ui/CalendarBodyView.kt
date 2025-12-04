package jp.uhimania.timecardclientandroid.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import jp.uhimania.timecardclientandroid.R
import jp.uhimania.timecardclientandroid.data.BreakTime
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.TimeRecord
import jp.uhimania.timecardclientandroid.data.datesOf
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import java.util.Calendar

@Composable
fun CalendarBodyView(
    records: List<CalendarRecord>,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier
    ) {
        item {
            Row(
                modifier = Modifier.padding(dimensionResource(R.dimen.padding_small))
            ) {
                Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) { Text("") }
                Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) { Text(stringResource(R.string.header_check_in)) }
                Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) { Text(stringResource(R.string.header_check_out)) }
                Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) { Text(stringResource(R.string.header_break_start)) }
                Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) { Text(stringResource(R.string.header_break_start)) }
            }
            HorizontalDivider(
                modifier = Modifier.padding(
                    start = dimensionResource(R.dimen.padding_medium),
                    end = dimensionResource(R.dimen.padding_medium)
                )
            )
        }

        items(records) {
            CalendarRecordView(it)
            HorizontalDivider(
                modifier = Modifier.padding(
                    start = dimensionResource(R.dimen.padding_medium),
                    end = dimensionResource(R.dimen.padding_medium)
                )
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun CalendarBodyViewPreview() {
    TimeCardClientAndroidTheme {
        val records = Calendar.getInstance().datesOf(2025, 12).map {
            val breakTime = BreakTime(start = it, end = it)
            val record = TimeRecord(checkIn = it, checkOut = it, breakTimes = listOf(breakTime))
            CalendarRecord(date = it, records = listOf(record))
        }
        CalendarBodyView(records)
    }
}
