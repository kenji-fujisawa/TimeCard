package jp.uhimania.timecardclientandroid.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.DoNotDisturbOn
import androidx.compose.material3.Card
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
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
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import java.text.SimpleDateFormat
import java.util.Date

@Composable
fun CalendarDetailView(
    record: CalendarRecord,
    onRecordChange: (CalendarRecord) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var showDelete by rememberSaveable { mutableStateOf(false) }

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Header(
            date = record.date,
            showDelete = showDelete,
            onBack = onBack,
            onEdit = { showDelete = !showDelete }
        )

        LazyColumn(horizontalAlignment = Alignment.CenterHorizontally) {
            items(record.records) {
                TimeRecordView(
                    record = it,
                    showDelete = showDelete,
                    onRecordChange = { timeRecord ->
                        val recs = record.records.toMutableList()
                        val index = recs.indexOfFirst { rec -> rec.id == timeRecord.id }
                        recs[index] = timeRecord
                        onRecordChange(record.copy(records = recs.toList()))
                    },
                    onDeleteRecord = { timeRecord ->
                        val recs = record.records.toMutableList()
                        recs.remove(timeRecord)
                        onRecordChange(record.copy(records = recs.toList()))
                    }
                )
            }

            item {
                TextButton(
                    onClick = {
                        val rec = TimeRecord(checkIn = record.date, checkOut = record.date, breakTimes = listOf())
                        val recs = record.records.plus(rec)
                        onRecordChange(record.copy(records = recs))
                    }
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
    record: TimeRecord,
    showDelete: Boolean,
    onRecordChange: (TimeRecord) -> Unit,
    onDeleteRecord: (TimeRecord) -> Unit,
    modifier: Modifier = Modifier
) {
    Card(modifier = modifier.padding(dimensionResource(R.dimen.padding_large))) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            AnimatedVisibility(showDelete) {
                IconButton(
                    onClick = { onDeleteRecord(record) }
                ) {
                    Icon(
                        imageVector = Icons.Default.DoNotDisturbOn,
                        contentDescription = Icons.Default.DoNotDisturbOn.name,
                        tint = Color.Red
                    )
                }
            }

            Column {
                record.checkIn?.let {
                    DateTimePicker(
                        label = stringResource(R.string.label_check_in),
                        date = it,
                        onDateChange = { date -> onRecordChange(record.copy(checkIn = date)) },
                        modifier = modifier.padding(dimensionResource(R.dimen.padding_large))
                    )
                }
                HorizontalDivider()
                record.checkOut?.let {
                    DateTimePicker(
                        label = stringResource(R.string.label_check_out),
                        date = it,
                        onDateChange = { date -> onRecordChange(record.copy(checkOut = date)) },
                        modifier = modifier.padding(dimensionResource(R.dimen.padding_large))
                    )
                }
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
                    onBreakTimeChange = { breakTime ->
                        val recs = record.breakTimes.toMutableList()
                        val index = recs.indexOfFirst { rec -> rec.id == breakTime.id }
                        recs[index] = breakTime
                        onRecordChange(record.copy(breakTimes = recs.toList()))
                    },
                    onDeleteBreakTime = { breakTime ->
                        val recs = record.breakTimes.toMutableList()
                        recs.remove(breakTime)
                        onRecordChange(record.copy(breakTimes = recs.toList()))
                    }
                )
            }

            TextButton(
                onClick = {
                    val rec = BreakTime(start = record.checkIn, end = record.checkIn)
                    val recs = record.breakTimes.plus(rec)
                    onRecordChange(record.copy(breakTimes = recs))
                }
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
    breakTime: BreakTime,
    showDelete: Boolean,
    onBreakTimeChange: (BreakTime) -> Unit,
    onDeleteBreakTime: (BreakTime) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically
    ) {
        AnimatedVisibility(showDelete) {
            IconButton(
                onClick = { onDeleteBreakTime(breakTime) }
            ) {
                Icon(
                    imageVector = Icons.Default.DoNotDisturbOn,
                    contentDescription = Icons.Default.DoNotDisturbOn.name,
                    tint = Color.Red
                )
            }
        }

        Column {
            breakTime.start?.let {
                DateTimePicker(
                    label = stringResource(R.string.label_break_start),
                    date = it,
                    onDateChange = { date -> onBreakTimeChange(breakTime.copy(start = date)) },
                    modifier = modifier.padding(dimensionResource(R.dimen.padding_large))
                )
            }
            HorizontalDivider()
            breakTime.end?.let {
                DateTimePicker(
                    label = stringResource(R.string.label_break_end),
                    date = it,
                    onDateChange = { date -> onBreakTimeChange(breakTime.copy(end = date)) },
                    modifier = modifier.padding(dimensionResource(R.dimen.padding_large))
                )
            }
            HorizontalDivider()
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun CalendarDetailViewPreview() {
    TimeCardClientAndroidTheme {
        val breakTime = BreakTime(start = Date(), end = Date())
        val timeRecord = TimeRecord(checkIn = Date(), checkOut = Date(), breakTimes = listOf(breakTime))
        val record = CalendarRecord(date = Date(), records = listOf(timeRecord))
        CalendarDetailView(
            record = record,
            onRecordChange = {},
            onBack = {}
        )
    }
}
