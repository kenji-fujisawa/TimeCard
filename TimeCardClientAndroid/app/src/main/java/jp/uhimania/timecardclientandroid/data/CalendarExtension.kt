package jp.uhimania.timecardclientandroid.data

import java.util.Calendar
import java.util.Date

fun Calendar.datesOf(year: Int, month: Int): List<Date> {
    val dates = mutableListOf<Date>()
    val calendar = Calendar.getInstance()
    calendar.clear()
    calendar.set(year, month - 1, 1)

    var date = calendar.time
    while (date.month() == month) {
        dates.add(date)
        calendar.add(Calendar.DAY_OF_MONTH, 1)
        date = calendar.time
    }

    return dates.toList()
}
