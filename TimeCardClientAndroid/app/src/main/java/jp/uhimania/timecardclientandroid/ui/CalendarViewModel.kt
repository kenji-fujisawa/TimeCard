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
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.DefaultCalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.month
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
)

class CalendarViewModel(
    private val calendarRecordRepository: CalendarRecordRepository
) : ViewModel() {
    private val _date = MutableStateFlow(Date())
    private val _isLoading = MutableStateFlow(false)
    private val _message = MutableStateFlow<Int?>(null)

    @OptIn(ExperimentalCoroutinesApi::class)
    private val _records = _date
        .flatMapLatest { calendarRecordRepository.getRecords(it.year(), it.month()) }
        .onEach { _isLoading.value = false }

    val uiState = combine(_date, _isLoading, _records, _message) { date, loading, recs, msg ->
        CalendarUiState(
            date = date,
            isLoading = loading,
            records = recs,
            message = msg
        )
    }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = CalendarUiState(isLoading = true)
        )

    fun updateDate(date: Date) {
        _date.value = date
        _isLoading.value = true
    }

    fun updateRecord(record: CalendarRecord) {
        viewModelScope.launch {
            try {
                calendarRecordRepository.updateRecord(
                    source = uiState.value.records,
                    record = record
                )
            } catch (_: Exception) {
                _message.value = R.string.error_update_record_failed
            }
        }
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
