package jp.uhimania.timecardclientandroid.data

import java.util.Calendar
import java.util.Date
import java.util.Locale

data class TimeInterval(val value: Long) {
    fun format(): String {
        val hours = value / 60 / 60
        val minutes = (value - hours * 60 * 60) / 60
        return String.format(Locale.getDefault(), "%02d:%02d", hours, minutes)
    }
}

fun Date.timeIntervalSince(date: Date): TimeInterval {
    val elapsed = this.time / 1000 - date.time / 1000
    return TimeInterval(elapsed)
}

fun Date.startOfDay(): Date {
    val calendar = Calendar.getInstance()
    calendar.time = this
    calendar.set(Calendar.HOUR_OF_DAY, 0)
    calendar.set(Calendar.MINUTE, 0)
    calendar.set(Calendar.SECOND, 0)
    calendar.set(Calendar.MILLISECOND, 0)
    return calendar.time
}
