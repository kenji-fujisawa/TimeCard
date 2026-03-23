package jp.uhimania.timecardclientandroid.ui

import android.annotation.SuppressLint
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.lifecycle.viewmodel.compose.viewModel
import jp.uhimania.timecardclientandroid.R
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.datesOf
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import java.util.Calendar
import java.util.Date

@Composable
fun CalendarView(
    onDateSelect: (Date) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: CalendarViewModel = viewModel(factory = CalendarViewModel.Factory),
    snackbarHostState: SnackbarHostState = remember { SnackbarHostState() }
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        modifier = modifier.fillMaxSize(),
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { innerPadding ->
        if (uiState.isLoading) {
            LoadingView(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
            )
        } else {
            Column(
                modifier = Modifier.padding(innerPadding),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                MonthSelector(
                    date = uiState.date,
                    onDateChange = { viewModel.updateDate(it) },
                    modifier = Modifier.padding(dimensionResource(R.dimen.padding_large))
                )
                CalendarBodyView(
                    records = uiState.records,
                    onDateSelect = onDateSelect
                )
            }

            uiState.message?.let {
                val message = stringResource(it)
                LaunchedEffect(snackbarHostState,
                    viewModel, message) {
                    snackbarHostState.showSnackbar(message)
                    viewModel.messageShown()
                }
            }
        }
    }
}

@SuppressLint("ViewModelConstructorInComposable")
@Preview(showBackground = true)
@Composable
private fun CalendarViewPreview() {
    class FakeCalendarRecordRepository : CalendarRecordRepository {
        override fun getRecordsStream(year: Int, month: Int): Flow<List<CalendarRecord>> {
            val records = Calendar.getInstance().datesOf(year, month).map {
                CalendarRecord(it, listOf())
            }
            return flowOf(records)
        }

        override suspend fun getRecord(year: Int, month: Int, day: Int): CalendarRecord {
            return CalendarRecord(Date(), listOf())
        }
        override suspend fun updateRecord(record: CalendarRecord) {}
    }

    TimeCardClientAndroidTheme {
        val repository = FakeCalendarRecordRepository()
        val viewModel = CalendarViewModel(repository)
        CalendarView(
            onDateSelect = {},
            viewModel = viewModel
        )
    }
}
