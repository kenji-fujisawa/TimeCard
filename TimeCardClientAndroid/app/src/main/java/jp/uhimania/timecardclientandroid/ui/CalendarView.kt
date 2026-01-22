package jp.uhimania.timecardclientandroid.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.tooling.preview.Preview
import jp.uhimania.timecardclientandroid.R
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.datesOf
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date

@Composable
fun CalendarView(
    date: Date,
    records: List<CalendarRecord>,
    onDateChange: (Date) -> Unit,
    onDateSelect: (CalendarRecord) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        MonthSelector(
            date = date,
            onDateChange = onDateChange,
            modifier = Modifier.padding(dimensionResource(R.dimen.padding_large))
        )
        CalendarBodyView(
            records = records,
            onDateSelect = onDateSelect
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun CalendarViewPreview() {
    TimeCardClientAndroidTheme {
        val formatter = SimpleDateFormat("yyyy-MM-dd")
        val date = formatter.parse("2025-12-01")
        val records = Calendar.getInstance().datesOf(2025, 12).map { CalendarRecord(date = it, records = listOf()) }
        CalendarView(
            date = date ?: Date(),
            records = records,
            onDateChange = {},
            onDateSelect = {}
        )
    }
}
