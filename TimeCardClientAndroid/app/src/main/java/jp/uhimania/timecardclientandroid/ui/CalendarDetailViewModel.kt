package jp.uhimania.timecardclientandroid.ui

import androidx.annotation.StringRes
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.Companion.APPLICATION_KEY
import androidx.lifecycle.createSavedStateHandle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import jp.uhimania.timecardclientandroid.R
import jp.uhimania.timecardclientandroid.TimeCardClientApplication
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.DefaultCalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.day
import jp.uhimania.timecardclientandroid.data.month
import jp.uhimania.timecardclientandroid.data.year
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.Date

data class CalendarDetailUiState(
    val record: CalendarRecord = CalendarRecord(Date(), listOf()),
    val isLoading: Boolean = false,
    @param:StringRes val message: Int? = null
)

class CalendarDetailViewModel(
    private val calendarRecordRepository: CalendarRecordRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {
    private val date = Date(savedStateHandle[NavigationArgs.DATE_ARG] ?: 0)

    private val _uiState = MutableStateFlow(CalendarDetailUiState())
    val uiState = _uiState.asStateFlow()

    init {
        _uiState.update { it.copy(isLoading = true) }
        viewModelScope.launch {
            val record = calendarRecordRepository.getRecord(date.year(), date.month(), date.day())
            _uiState.update {
                it.copy(record = record, isLoading = false)
            }
        }
    }

    fun updateRecord(record: CalendarRecord) {
        _uiState.update { it.copy(record = record) }
    }

    fun saveChanges() {
        viewModelScope.launch {
            try {
                calendarRecordRepository.updateRecord(uiState.value.record)
            } catch (_: Exception) {
                _uiState.update { it.copy(message = R.string.error_update_record_failed) }
            }
        }
    }

    companion object {
        val Factory: ViewModelProvider.Factory = viewModelFactory {
            initializer {
                val app = this[APPLICATION_KEY] as TimeCardClientApplication
                val repository = DefaultCalendarRecordRepository(app.networkDataSource, app.localDataSource)
                val handle = createSavedStateHandle()
                CalendarDetailViewModel(repository, handle)
            }
        }
    }
}
