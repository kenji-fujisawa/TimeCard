package jp.uhimania.timecardclientandroid.ui

import androidx.annotation.StringRes
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.Companion.APPLICATION_KEY
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import jp.uhimania.timecardclientandroid.R
import jp.uhimania.timecardclientandroid.TimeCardClientApplication
import jp.uhimania.timecardclientandroid.data.BreakTime
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.DefaultCalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.TimeInterval
import jp.uhimania.timecardclientandroid.data.TimeRecord
import jp.uhimania.timecardclientandroid.data.month
import jp.uhimania.timecardclientandroid.data.startOfDay
import jp.uhimania.timecardclientandroid.data.timeIntervalSince
import jp.uhimania.timecardclientandroid.data.year
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.Date

data class CalendarUiState(
    val date: Date = Date(),
    val isLoading: Boolean = false,
    val records: List<CalendarRecord> = listOf(),
    @param:StringRes val message: Int? = null
) {
    data class BreakTime(
        val start: Date? = null,
        val end: Date? = null,
        val elapsed: TimeInterval? = null
    )

    data class TimeRecord(
        val checkIn: Date? = null,
        val checkOut: Date? = null,
        val elapsed: TimeInterval? = null,
        val breakTimes: List<BreakTime> = listOf()
    )

    data class CalendarRecord(
        val date: Date = Date(),
        val records: List<TimeRecord> = listOf()
    )
}

class CalendarViewModel(
    private val calendarRecordRepository: CalendarRecordRepository
) : ViewModel() {
    private val _date = MutableStateFlow(Date())
    private val _isLoading = MutableStateFlow(false)
    private val _message = MutableStateFlow<Int?>(null)

    @OptIn(ExperimentalCoroutinesApi::class)
    private val _records = _date
        .flatMapLatest { calendarRecordRepository.getRecordsStream(it.year(), it.month()) }
        .onEach { _isLoading.value = false }

    val uiState = combine(_date, _isLoading, _records, _message) { date, loading, recs, msg ->
        CalendarUiState(
            date = date,
            isLoading = loading,
            records = recs.map { it.asUiState() },
            message = msg
        )
    }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = CalendarUiState(isLoading = true)
        )

    init {
        refreshRecords()
    }

    private fun refreshRecords() {
        _isLoading.value = true

        viewModelScope.launch {
            try {
                calendarRecordRepository.refreshRecords(_date.value.year(), _date.value.month())
            } catch (_: Exception) {
                _message.value = R.string.error_get_records_failed
            }
        }
    }

    fun updateDate(date: Date) {
        _date.value = date
        refreshRecords()
    }

    fun messageShown() {
        _message.value = null
    }

    companion object {
        val Factory: ViewModelProvider.Factory = viewModelFactory {
            initializer {
                val app = this[APPLICATION_KEY] as TimeCardClientApplication
                val repository = DefaultCalendarRecordRepository(app.networkDataSource, app.localDataSource)
                CalendarViewModel(repository)
            }
        }
    }
}

fun CalendarRecord.asUiState(): CalendarUiState.CalendarRecord {
    return CalendarUiState.CalendarRecord(
        date = this.date,
        records = this.records.map { it.asUiState() }
    )
}

fun TimeRecord.asUiState(): CalendarUiState.TimeRecord {
    return CalendarUiState.TimeRecord(
        checkIn = this.checkIn,
        checkOut = this.checkOut,
        elapsed = this.checkOut?.timeIntervalSince(this.checkIn?.startOfDay() ?: Date()),
        breakTimes = this.breakTimes.map { it.asUiState() }
    )
}

fun BreakTime.asUiState(): CalendarUiState.BreakTime {
    return CalendarUiState.BreakTime(
        start = this.start,
        end = this.end,
        elapsed = this.end?.timeIntervalSince(this.start?.startOfDay() ?: Date())
    )
}
