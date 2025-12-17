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
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
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
    private val _uiState = MutableStateFlow(CalendarUiState())
    val uiState = _uiState.asStateFlow()

    init {
        fetchRecords()
    }

    fun updateDate(date: Date) {
        _uiState.update { it.copy(date = date) }
        fetchRecords()
    }

    private fun fetchRecords() {
        _uiState.update { it.copy(isLoading = true) }
        viewModelScope.launch {
            try {
                val date = uiState.value.date
                val records = calendarRecordRepository.getRecords(date.year(), date.month())
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        records = records
                    )
                }
            } catch (_: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        message = R.string.error_get_records_failed
                    )
                }
            }
        }
    }

    fun updateRecord(record: CalendarRecord) {
        viewModelScope.launch {
            try {
                val records = calendarRecordRepository.updateRecord(
                    source = uiState.value.records,
                    record = record
                )
                _uiState.update {
                    it.copy(records = records)
                }
            } catch (_: Exception) {
                _uiState.update {
                    it.copy(message = R.string.error_update_record_failed)
                }
            }
        }
    }

    fun messageShown() {
        _uiState.update {
            it.copy(message = null)
        }
    }

    companion object {
        val Factory: ViewModelProvider.Factory = viewModelFactory {
            initializer {
                val app = this[APPLICATION_KEY] as TimeCardClientApplication
                val repository = DefaultCalendarRecordRepository(app.networkDataSource)
                CalendarViewModel(repository)
            }
        }
    }
}
