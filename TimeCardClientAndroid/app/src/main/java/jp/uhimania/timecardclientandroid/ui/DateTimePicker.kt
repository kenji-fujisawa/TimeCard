package jp.uhimania.timecardclientandroid.ui

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import jp.uhimania.timecardclientandroid.R
import jp.uhimania.timecardclientandroid.data.hour
import jp.uhimania.timecardclientandroid.data.minute
import jp.uhimania.timecardclientandroid.data.second
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date

@Composable
fun DateTimePicker(
    label: String,
    date: Date,
    onDateChange: (Date) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label)
        Spacer(modifier = Modifier.weight(1f))
        DateFieldWithPicker(
            date = date,
            onDateChange = onDateChange
        )
        TimeFieldWithPicker(
            date = date,
            onDateChange = onDateChange
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DateFieldWithPicker(
    date: Date,
    onDateChange: (Date) -> Unit,
    modifier: Modifier = Modifier
) {
    var showModal by remember { mutableStateOf(false) }
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = date.time
    )

    val formatter = SimpleDateFormat("yyyy-MM-dd")
    OutlinedTextField(
        value = formatter.format(date),
        onValueChange = {},
        readOnly = true,
        modifier = modifier
            .width(dimensionResource(R.dimen.date_field_width))
            .pointerInput(date) {
                awaitEachGesture {
                    awaitFirstDown(pass = PointerEventPass.Initial)
                    val upEvent = waitForUpOrCancellation(pass = PointerEventPass.Initial)
                    if (upEvent != null) {
                        showModal = true
                    }
                }
            }
    )

    if (showModal) {
        DatePickerDialog(
            onDismissRequest = { showModal = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        datePickerState.selectedDateMillis?.let {
                            val calendar = Calendar.getInstance()
                            calendar.time = Date(it)
                            calendar.set(Calendar.HOUR_OF_DAY, date.hour())
                            calendar.set(Calendar.MINUTE, date.minute())
                            calendar.set(Calendar.SECOND, date.second())
                            onDateChange(calendar.time)
                        }
                        showModal = false
                    }
                ) { Text(stringResource(R.string.caption_ok)) }
            },
            dismissButton = {
                TextButton(
                    onClick = { showModal = false }
                ) { Text(stringResource(R.string.caption_cancel)) }
            }
        ) {
            DatePicker(datePickerState)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TimeFieldWithPicker(
    date: Date,
    onDateChange: (Date) -> Unit,
    modifier: Modifier = Modifier
) {
    var showModal by remember { mutableStateOf(false) }
    val timePickerState = rememberTimePickerState(
        initialHour = date.hour(),
        initialMinute = date.minute(),
        is24Hour = true
    )

    val formatter = SimpleDateFormat("HH:mm")
    OutlinedTextField(
        value = formatter.format(date),
        onValueChange = {},
        readOnly = true,
        modifier = modifier
            .padding(start = dimensionResource(R.dimen.padding_small))
            .width(dimensionResource(R.dimen.time_field_width))
            .pointerInput(date) {
                awaitEachGesture {
                    awaitFirstDown(pass = PointerEventPass.Initial)
                    val upEvent = waitForUpOrCancellation(pass = PointerEventPass.Initial)
                    if (upEvent != null) {
                        showModal = true
                    }
                }
            }
    )

    if (showModal) {
        AlertDialog(
            onDismissRequest = { showModal = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        val calendar = Calendar.getInstance()
                        calendar.time = date
                        calendar.set(Calendar.HOUR_OF_DAY, timePickerState.hour)
                        calendar.set(Calendar.MINUTE, timePickerState.minute)
                        onDateChange(calendar.time)
                        showModal = false
                    }
                ) { Text(stringResource(R.string.caption_ok)) }
            },
            dismissButton = {
                TextButton(
                    onClick = { showModal = false }
                ) { Text(stringResource(R.string.caption_cancel)) }
            },
            text = { TimePicker(timePickerState) }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun DateTimePickerPreview() {
    TimeCardClientAndroidTheme {
        DateTimePicker(
            label = "test",
            date = Date(),
            onDateChange = {}
        )
    }
}
