package jp.uhimania.timecardclientandroid.ui

import android.annotation.SuppressLint
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.DoNotDisturbOn
import androidx.compose.material.icons.filled.Done
import androidx.compose.material3.Card
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.FloatingActionButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.viewmodel.compose.viewModel
import jp.uhimania.timecardclientandroid.R
import jp.uhimania.timecardclientandroid.data.BreakTime
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.TimeRecord
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import java.text.SimpleDateFormat
import java.util.Date

@Composable
fun CalendarDetailView(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: CalendarDetailViewModel = viewModel(factory = CalendarDetailViewModel.Factory),
    snackbarHostState: SnackbarHostState = remember { SnackbarHostState() }
) {
    val uiState by viewModel.uiState.collectAsState()
    var showDelete by rememberSaveable { mutableStateOf(false) }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        snackbarHost = { SnackbarHost(snackbarHostState) },
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    if (uiState.valid) viewModel.onEvent(CalendarDetailUiEvent.SaveChanges)
                },
                containerColor = if (uiState.valid) {
                    FloatingActionButtonDefaults.containerColor
                } else {
                    MaterialTheme.colorScheme.surfaceVariant
                }
            ) {
                Icon(
                    imageVector = Icons.Filled.Done,
                    contentDescription = Icons.Filled.Done.name
                )
            }
        }
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
                Header(
                    date = uiState.date,
                    showDelete = showDelete,
                    onBack = onBack,
                    onEdit = { showDelete = !showDelete }
                )

                LazyColumn(horizontalAlignment = Alignment.CenterHorizontally) {
                    items(uiState.records) {
                        TimeRecordView(
                            record = it,
                            showDelete = showDelete,
                            onEvent = { event -> viewModel.onEvent(event) }
                        )
                    }

                    item {
                        TextButton(
                            onClick = { viewModel.onEvent(CalendarDetailUiEvent.AddTimeRecord) }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = Icons.Default.Add.name
                            )
                            Text(stringResource(R.string.caption_add_time_record))
                        }
                    }
                }
            }

            uiState.message?.let {
                val message = stringResource(it)
                LaunchedEffect(snackbarHostState,
                    viewModel, message) {
                    snackbarHostState.showSnackbar(message)
                    viewModel.onEvent(CalendarDetailUiEvent.MessageShown)
                }
            }
        }
    }
}

@Composable
private fun Header(
    date: Date,
    showDelete: Boolean,
    onBack: () -> Unit,
    onEdit: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onBack) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = Icons.AutoMirrored.Filled.ArrowBack.name
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        val formatter = SimpleDateFormat(stringResource(R.string.format_month_day))
        Text(formatter.format(date))

        Spacer(modifier = Modifier.weight(1f))

        TextButton(onClick = onEdit) {
            val done = stringResource(R.string.caption_done)
            val edit = stringResource(R.string.caption_edit)
            Text(text = if (showDelete) done else edit)
        }
    }
}

@Composable
private fun TimeRecordView(
    record: CalendarDetailUiState.TimeRecord,
    showDelete: Boolean,
    onEvent: (CalendarDetailUiEvent) -> Unit,
    modifier: Modifier = Modifier
) {
    Card(modifier = modifier.padding(dimensionResource(R.dimen.padding_large))) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            AnimatedVisibility(showDelete) {
                IconButton(
                    onClick = { onEvent(CalendarDetailUiEvent.RemoveTimeRecord(record.id)) }
                ) {
                    Icon(
                        imageVector = Icons.Default.DoNotDisturbOn,
                        contentDescription = Icons.Default.DoNotDisturbOn.name,
                        tint = Color.Red
                    )
                }
            }

            Column {
                DateTimePicker(
                    label = stringResource(R.string.label_check_in),
                    date = record.checkIn,
                    onDateChange = { date -> onEvent(CalendarDetailUiEvent.UpdateTimeRecord(record.id, date, record.checkOut)) },
                    isError = !record.valid,
                    modifier = modifier.padding(dimensionResource(R.dimen.padding_large))
                )
                HorizontalDivider()
                DateTimePicker(
                    label = stringResource(R.string.label_check_out),
                    date = record.checkOut,
                    onDateChange = { date -> onEvent(CalendarDetailUiEvent.UpdateTimeRecord(record.id, record.checkIn, date)) },
                    isError = !record.valid,
                    modifier = modifier.padding(dimensionResource(R.dimen.padding_large))
                )
                HorizontalDivider()
            }
        }

        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            record.breakTimes.forEach {
                BreakTimeView(
                    breakTime = it,
                    showDelete = showDelete,
                    onBreakTimeChange = { id, start, end ->
                        onEvent(CalendarDetailUiEvent.UpdateBreakTime(record.id, id, start, end))
                    },
                    onDeleteBreakTime = { id ->
                        onEvent(CalendarDetailUiEvent.RemoveBreakTime(record.id, id))
                    }
                )
            }

            TextButton(
                onClick = { onEvent(CalendarDetailUiEvent.AddBreakTime(record.id)) }
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = Icons.Default.Add.name
                )
                Text(stringResource(R.string.caption_add_break_time))
            }
        }
    }
}

@Composable
private fun BreakTimeView(
    breakTime: CalendarDetailUiState.BreakTime,
    showDelete: Boolean,
    onBreakTimeChange: (String, Date, Date) -> Unit,
    onDeleteBreakTime: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically
    ) {
        AnimatedVisibility(showDelete) {
            IconButton(
                onClick = { onDeleteBreakTime(breakTime.id) }
            ) {
                Icon(
                    imageVector = Icons.Default.DoNotDisturbOn,
                    contentDescription = Icons.Default.DoNotDisturbOn.name,
                    tint = Color.Red
                )
            }
        }

        Column {
            DateTimePicker(
                label = stringResource(R.string.label_break_start),
                date = breakTime.start,
                onDateChange = { date -> onBreakTimeChange(breakTime.id, date, breakTime.end) },
                isError = !breakTime.valid,
                modifier = modifier.padding(dimensionResource(R.dimen.padding_large))
            )
            HorizontalDivider()
            DateTimePicker(
                label = stringResource(R.string.label_break_end),
                date = breakTime.end,
                onDateChange = { date -> onBreakTimeChange(breakTime.id, breakTime.start, date) },
                isError = !breakTime.valid,
                modifier = modifier.padding(dimensionResource(R.dimen.padding_large))
            )
            HorizontalDivider()
        }
    }
}

@SuppressLint("ViewModelConstructorInComposable")
@Preview(showBackground = true)
@Composable
private fun CalendarDetailViewPreview() {
    class FakeCalendarRecordRepository : CalendarRecordRepository {
        override fun getRecordsStream(year: Int, month: Int): Flow<List<CalendarRecord>> {
            return flowOf()
        }

        override suspend fun getRecord(year: Int, month: Int, day: Int): CalendarRecord {
            val breakTime = BreakTime(start = Date(), end = Date())
            val timeRecord = TimeRecord(checkIn = Date(), checkOut = Date(), breakTimes = listOf(breakTime))
            return CalendarRecord(date = Date(), records = listOf(timeRecord))
        }

        override suspend fun updateRecord(record: CalendarRecord) {}
    }

    TimeCardClientAndroidTheme {
        val repository = FakeCalendarRecordRepository()
        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)
        CalendarDetailView(
            onBack = {},
            viewModel = viewModel
        )
    }
}
