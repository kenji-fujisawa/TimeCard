package jp.uhimania.timecardclientandroid.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.lifecycle.viewmodel.compose.viewModel
import jp.uhimania.timecardclientandroid.R
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.datesOf
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import java.util.Calendar

@Composable
fun CalendarView(
    modifier: Modifier = Modifier,
    viewModel: CalendarViewModel = viewModel(factory = CalendarViewModel.Factory)
) {
    val uiState by viewModel.uiState.collectAsState()
    if (uiState.isLoading) {
        LoadingView(
            modifier = modifier.fillMaxSize()
        )
    } else {
        Column(
            modifier = modifier,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            MonthSelector(
                date = uiState.date,
                onDateChange = { viewModel.updateDate(it) },
                modifier = Modifier.padding(dimensionResource(R.dimen.padding_large))
            )
            CalendarBodyView(uiState.records)
        }
    }
}

@Composable
private fun LoadingView(
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}

@Preview(showBackground = true)
@Composable
private fun CalendarViewPreview() {
    TimeCardClientAndroidTheme {
        val vm = CalendarViewModel(FakeCalendarRecordRepository())
        CalendarView(viewModel = vm)
    }
}

private class FakeCalendarRecordRepository : CalendarRecordRepository {
    override suspend fun getRecords(year: Int, month: Int): List<CalendarRecord> {
        return Calendar.getInstance().datesOf(year, month).map {
            CalendarRecord(it, listOf())
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun LoadingViewPreview() {
    TimeCardClientAndroidTheme {
        LoadingView()
    }
}
