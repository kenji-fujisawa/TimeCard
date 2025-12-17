package jp.uhimania.timecardclientandroid.ui

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import jp.uhimania.timecardclientandroid.R
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date

@Composable
fun MonthSelector(
    date: Date,
    onDateChange: (Date) -> Unit,
    modifier: Modifier = Modifier,
    formatter: String = stringResource(R.string.format_year_month)
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(
            onClick = { onDateChange(addMonths(date, -1)) }
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                contentDescription = Icons.AutoMirrored.Filled.KeyboardArrowLeft.name,
                modifier = Modifier.fillMaxSize()
            )
        }

        Text(
            text = SimpleDateFormat(formatter).format(date),
            style = MaterialTheme.typography.displaySmall
        )

        IconButton(
            onClick = { onDateChange(addMonths(date, 1)) }
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = Icons.AutoMirrored.Filled.KeyboardArrowRight.name,
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}

private fun addMonths(date: Date, month: Int): Date {
    val calendar = Calendar.getInstance()
    calendar.time = date
    calendar.add(Calendar.MONTH, month)
    return calendar.time
}

@Preview(showBackground = true)
@Composable
private fun MonthSelectorPreview() {
    var date by remember { mutableStateOf(Date()) }
    MonthSelector(date, { date = it })
}
