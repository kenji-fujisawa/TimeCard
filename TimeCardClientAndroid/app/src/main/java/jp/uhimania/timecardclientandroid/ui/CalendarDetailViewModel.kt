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
import jp.uhimania.timecardclientandroid.data.BreakTime
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.DefaultCalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.TimeRecord
import jp.uhimania.timecardclientandroid.data.day
import jp.uhimania.timecardclientandroid.data.month
import jp.uhimania.timecardclientandroid.data.year
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.Date
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

data class CalendarDetailUiState(
    val date: Date = Date(),
    val records: List<TimeRecord> = listOf(),
    val valid: Boolean = true,
    val isLoading: Boolean = false,
    @param:StringRes val message: Int? = null
) {
    data class BreakTime @OptIn(ExperimentalUuidApi::class) constructor(
        val id: String = Uuid.random().toString(),
        val start: Date = Date(),
        val end: Date = Date(),
        val valid: Boolean = true
    )

    data class TimeRecord @OptIn(ExperimentalUuidApi::class) constructor(
        val id: String = Uuid.random().toString(),
        val checkIn: Date = Date(),
        val checkOut: Date = Date(),
        val breakTimes: List<BreakTime> = listOf(),
        val valid: Boolean = true
    )
}

sealed class CalendarDetailUiEvent {
    data object AddTimeRecord : CalendarDetailUiEvent()
    data class UpdateTimeRecord(val id: String, val checkIn: Date, val checkOut: Date) : CalendarDetailUiEvent()
    data class RemoveTimeRecord(val id: String) : CalendarDetailUiEvent()
    data class AddBreakTime(val timeRecordId: String) : CalendarDetailUiEvent()
    data class UpdateBreakTime(val timeRecordId: String, val breakTimeId: String, val start: Date, val end: Date) : CalendarDetailUiEvent()
    data class RemoveBreakTime(val timeRecordId: String, val breakTimeId: String) : CalendarDetailUiEvent()
    data object SaveChanges : CalendarDetailUiEvent()
    data object MessageShown : CalendarDetailUiEvent()
}

class CalendarDetailViewModel(
    private val calendarRecordRepository: CalendarRecordRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {
    private val date = Date(savedStateHandle[NavigationArgs.DATE_ARG] ?: 0)

    private val _uiState = MutableStateFlow(CalendarDetailUiState(date = date))
    val uiState = _uiState.asStateFlow()

    init {
        _uiState.update { it.copy(isLoading = true) }
        viewModelScope.launch {
            val record = calendarRecordRepository.getRecord(date.year(), date.month(), date.day())
            _uiState.update {
                validate(record.date, record.records.map { it.asDetailUiState() })
                    .copy(isLoading = false)
            }
        }
    }

    fun onEvent(event: CalendarDetailUiEvent) {
        when (event) {
            is CalendarDetailUiEvent.AddTimeRecord -> addTimeRecord()
            is CalendarDetailUiEvent.UpdateTimeRecord -> updateTimeRecord(event.id, event.checkIn, event.checkOut)
            is CalendarDetailUiEvent.RemoveTimeRecord -> removeTimeRecord(event.id)
            is CalendarDetailUiEvent.AddBreakTime -> addBreakTimeTo(event.timeRecordId)
            is CalendarDetailUiEvent.UpdateBreakTime -> updateBreakTime(event.timeRecordId, event.breakTimeId, event.start, event.end)
            is CalendarDetailUiEvent.RemoveBreakTime -> removeBreakTime(event.timeRecordId, event.breakTimeId)
            is CalendarDetailUiEvent.SaveChanges -> saveChanges()
            is CalendarDetailUiEvent.MessageShown -> messageShown()
        }
    }

    private fun addTimeRecord() {
        val list = _uiState.value.records.toMutableList()
        val date = _uiState.value.date
        list.add(CalendarDetailUiState.TimeRecord(checkIn = date, checkOut = date))
        _uiState.update { validate(_uiState.value.date, list) }
    }

    private fun updateTimeRecord(id: String, checkIn: Date, checkOut: Date) {
        val list = _uiState.value.records.toMutableList()
        val index = list.indexOfFirst { it.id == id }
        if (index != -1) {
            list[index] = list[index].copy(checkIn = checkIn, checkOut = checkOut)
            _uiState.update { validate(_uiState.value.date, list) }
        }
    }

    private fun removeTimeRecord(id: String) {
        val list = _uiState.value.records.toMutableList()
        list.removeAll { it.id == id }
        _uiState.update { validate(_uiState.value.date, list) }
    }

    private fun addBreakTimeTo(timeRecordId: String) {
        val timeList = _uiState.value.records.toMutableList()
        val timeIndex = timeList.indexOfFirst { it.id == timeRecordId }
        if (timeIndex != -1) {
            val breakList = timeList[timeIndex].breakTimes.toMutableList()
            val date = timeList[timeIndex].checkIn
            breakList.add(CalendarDetailUiState.BreakTime(start = date, end = date))
            timeList[timeIndex] = timeList[timeIndex].copy(breakTimes = breakList)
            _uiState.update { validate(_uiState.value.date, timeList) }
        }
    }

    private fun updateBreakTime(timeRecordId: String, breakTimeId: String, start: Date, end: Date) {
        val timeList = _uiState.value.records.toMutableList()
        val timeIndex = timeList.indexOfFirst { it.id == timeRecordId }
        if (timeIndex != -1) {
            val breakList = timeList[timeIndex].breakTimes.toMutableList()
            val breakIndex = breakList.indexOfFirst { it.id == breakTimeId }
            if (breakIndex != -1) {
                breakList[breakIndex] = breakList[breakIndex].copy(start = start, end = end)
                timeList[timeIndex] = timeList[timeIndex].copy(breakTimes = breakList)
                _uiState.update { validate(_uiState.value.date, timeList) }
            }
        }
    }

    private fun removeBreakTime(timeRecordId: String, breakTimeId: String) {
        val timeList = _uiState.value.records.toMutableList()
        val timeIndex = timeList.indexOfFirst { it.id == timeRecordId }
        if (timeIndex != -1) {
            val breakList = timeList[timeIndex].breakTimes.toMutableList()
            breakList.removeAll { it.id == breakTimeId }
            timeList[timeIndex] = timeList[timeIndex].copy(breakTimes = breakList)
            _uiState.update { validate(_uiState.value.date, timeList) }
        }
    }

    private fun validate(date: Date, records: List<CalendarDetailUiState.TimeRecord>): CalendarDetailUiState {
        val invalidTimeRecordIds = mutableSetOf<String>()
        val timeList = records.sortedBy { it.checkIn }
        timeList.filter { !isValid(date, it) }
            .forEach { invalidTimeRecordIds.add(it.id) }

        for ((a, b) in timeList.zip(timeList.drop(1))) {
            if (a.checkOut > b.checkIn) {
                invalidTimeRecordIds.add(a.id)
                invalidTimeRecordIds.add(b.id)
            }
        }

        val invalidBreakTimeIds = mutableSetOf<String>()
        for (rec in timeList) {
            val breakList = rec.breakTimes.sortedBy { it.start }
            breakList.filter { !isValid(rec, it) }
                .forEach { invalidBreakTimeIds.add(it.id) }

            for ((a, b) in breakList.zip(breakList.drop(1))) {
                if (a.end > b.start) {
                    invalidBreakTimeIds.add(a.id)
                    invalidBreakTimeIds.add(b.id)
                }
            }
        }

        val list = records.map { rec ->
            val breakList = rec.breakTimes.map { it.copy(valid = !invalidBreakTimeIds.contains(it.id)) }
            rec.copy(
                breakTimes = breakList,
                valid = !invalidTimeRecordIds.contains(rec.id)
            )
        }

        return _uiState.value.copy(
            date = date,
            records = list,
            valid = invalidTimeRecordIds.isEmpty() && invalidBreakTimeIds.isEmpty()
        )
    }

    private fun isValid(date: Date, record: CalendarDetailUiState.TimeRecord): Boolean {
        if (record.checkIn > record.checkOut) return false
        if (record.checkIn < date) return false

        return true
    }

    private fun isValid(timeRecord: CalendarDetailUiState.TimeRecord, breakTime: CalendarDetailUiState.BreakTime): Boolean {
        if (breakTime.start > breakTime.end) return false
        if (breakTime.start < timeRecord.checkIn) return false
        if (breakTime.end > timeRecord.checkOut) return false

        return true
    }

    private fun saveChanges() {
        viewModelScope.launch {
            try {
                val record = CalendarRecord(
                    date = _uiState.value.date,
                    records = _uiState.value.records.map { it.asTimeRecord() }
                )
                calendarRecordRepository.updateRecord(record)
            } catch (_: Exception) {
                _uiState.update { it.copy(message = R.string.error_update_record_failed) }
            }
        }
    }

    private fun messageShown() {
        _uiState.update { it.copy(message = null) }
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

fun TimeRecord.asDetailUiState(): CalendarDetailUiState.TimeRecord {
    return CalendarDetailUiState.TimeRecord(
        id = this.id,
        checkIn = this.checkIn ?: Date(),
        checkOut = this.checkOut ?: Date(),
        breakTimes = this.breakTimes.map { it.asDetailUiState() }
    )
}

fun BreakTime.asDetailUiState(): CalendarDetailUiState.BreakTime {
    return CalendarDetailUiState.BreakTime(
        id = this.id,
        start = this.start ?: Date(),
        end = this.end ?: Date()
    )
}

fun CalendarDetailUiState.TimeRecord.asTimeRecord(): TimeRecord {
    return TimeRecord(
        id = this.id,
        checkIn = this.checkIn,
        checkOut = this.checkOut,
        breakTimes = this.breakTimes.map { it.asBreakTime() }
    )
}

fun CalendarDetailUiState.BreakTime.asBreakTime(): BreakTime {
    return BreakTime(
        id = this.id,
        start = this.start,
        end = this.end
    )
}
