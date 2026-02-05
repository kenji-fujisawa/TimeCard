package jp.uhimania.timecardclientandroid.data

import jp.uhimania.japanholidays.Holidays
import java.util.Calendar
import java.util.Date

fun Date.year(): Int {
    val calendar = Calendar.getInstance()
    calendar.time = this
    return calendar.get(Calendar.YEAR)
}

fun Date.month(): Int {
    val calendar = Calendar.getInstance()
    calendar.time = this
    return calendar.get(Calendar.MONTH) + 1
}

fun Date.day(): Int {
    val calendar = Calendar.getInstance()
    calendar.time = this
    return calendar.get(Calendar.DAY_OF_MONTH)
}

fun Date.hour(): Int {
    val calendar = Calendar.getInstance()
    calendar.time = this
    return calendar.get(Calendar.HOUR_OF_DAY)
}

fun Date.minute(): Int {
    val calendar = Calendar.getInstance()
    calendar.time = this
    return calendar.get(Calendar.MINUTE)
}

fun Date.second(): Int {
    val calendar = Calendar.getInstance()
    calendar.time = this
    return calendar.get(Calendar.SECOND)
}

fun Date.isHoliday(): Boolean {
    val calendar = Calendar.getInstance()
    calendar.time = this
    val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
    return dayOfWeek == Calendar.SUNDAY || dayOfWeek == Calendar.SATURDAY || Holidays.isHoliday(this)
}
