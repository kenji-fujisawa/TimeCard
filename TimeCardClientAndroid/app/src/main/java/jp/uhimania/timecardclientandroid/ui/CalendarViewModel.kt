package jp.uhimania.timecardclientandroid.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.Companion.APPLICATION_KEY
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
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
    val records: List<CalendarRecord> = listOf()
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
            val date = uiState.value.date
            val records = calendarRecordRepository.getRecords(date.year(), date.month())
            _uiState.update {
                it.copy(
                    isLoading = false,
                    records = records
                )
            }
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
