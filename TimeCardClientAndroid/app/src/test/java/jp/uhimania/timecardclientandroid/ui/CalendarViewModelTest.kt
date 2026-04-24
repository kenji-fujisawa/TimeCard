package jp.uhimania.timecardclientandroid.ui

import jp.uhimania.timecardclientandroid.data.BreakTime
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.TimeRecord
import jp.uhimania.timecardclientandroid.data.month
import jp.uhimania.timecardclientandroid.data.year
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class CalendarViewModelTest {
    @OptIn(ExperimentalCoroutinesApi::class)
    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun testElapsed_TimeRecord() {
        val format = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        var record = TimeRecord(
            checkIn = format.parse("2026-04-01 08:00:00"),
            checkOut = format.parse("2026-04-01 08:30:00"),
            breakTimes = listOf()
        )
        assertEquals("08:30", record.asUiState().elapsed?.format())

        record = TimeRecord(
            checkIn = format.parse("2026-04-01 08:00:00"),
            checkOut = format.parse("2026-04-01 17:00:00"),
            breakTimes = listOf()
        )
        assertEquals("17:00", record.asUiState().elapsed?.format())

        record = TimeRecord(
            checkIn = format.parse("2026-04-01 08:00:00"),
            checkOut = format.parse("2026-04-02 02:00:00"),
            breakTimes = listOf()
        )
        assertEquals("26:00", record.asUiState().elapsed?.format())
    }

    @Test
    fun testElapsed_BreakTime() {
        val format = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        var record = BreakTime(
            start = format.parse("2026-04-01 08:00:00"),
            end = format.parse("2026-04-01 08:30:00")
        )
        assertEquals("08:30", record.asUiState().elapsed?.format())

        record = BreakTime(
            start = format.parse("2026-04-01 08:00:00"),
            end = format.parse("2026-04-01 17:00:00")
        )
        assertEquals("17:00", record.asUiState().elapsed?.format())

        record = BreakTime(
            start = format.parse("2026-04-01 08:00:00"),
            end = format.parse("2026-04-02 02:00:00")
        )
        assertEquals("26:00", record.asUiState().elapsed?.format())
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testUiState() = runTest {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val repository = FakeCalendarRecordRepository()
        val viewModel = CalendarViewModel(repository)

        backgroundScope.launch(UnconfinedTestDispatcher()) {
            viewModel.uiState.collect {}
        }

        val formatter = SimpleDateFormat("yyyy-MM-dd")
        assertEquals(formatter.format(Date()), formatter.format(viewModel.uiState.value.date))
        assertTrue(viewModel.uiState.value.records.isEmpty())
        assertTrue(viewModel.uiState.value.isLoading)
        assertEquals(Date().year(), repository.year)
        assertEquals(Date().month(), repository.month)

        val record = CalendarRecord(
            date = formatter.parse("2026-04-01") ?: Date(),
            records = listOf(
                TimeRecord(
                    checkIn = formatter.parse("2026-04-01 09:00:00"),
                    checkOut = formatter.parse("2026-04-01 18:00:00"),
                    breakTimes = listOf()
                )
            )
        )
        repository.flow.emit(listOf(record))
        assertEquals(formatter.format(Date()), formatter.format(viewModel.uiState.value.date))
        assertEquals(1, viewModel.uiState.value.records.count())
        assertEquals(record.date, viewModel.uiState.value.records[0].date)
        assertEquals(record.records.count(), viewModel.uiState.value.records[0].records.count())
        assertEquals(record.records[0].checkIn, viewModel.uiState.value.records[0].records[0].checkIn)
        assertEquals(record.records[0].checkOut, viewModel.uiState.value.records[0].records[0].checkOut)
        assertEquals(record.records[0].breakTimes.count(), viewModel.uiState.value.records[0].records[0].breakTimes.count())
        assertFalse(viewModel.uiState.value.isLoading)

        viewModel.updateDate(formatter.parse("2026-04-02") ?: Date())
        assertEquals("2026-04-02", formatter.format(viewModel.uiState.value.date))
        assertEquals(1, viewModel.uiState.value.records.count())
        assertEquals(record.date, viewModel.uiState.value.records[0].date)
        assertEquals(record.records.count(), viewModel.uiState.value.records[0].records.count())
        assertEquals(record.records[0].checkIn, viewModel.uiState.value.records[0].records[0].checkIn)
        assertEquals(record.records[0].checkOut, viewModel.uiState.value.records[0].records[0].checkOut)
        assertEquals(record.records[0].breakTimes.count(), viewModel.uiState.value.records[0].records[0].breakTimes.count())
        assertTrue(viewModel.uiState.value.isLoading)
        assertEquals(2026, repository.year)
        assertEquals(4, repository.month)

        repository.flow.emit(listOf())
        assertEquals("2026-04-02", formatter.format(viewModel.uiState.value.date))
        assertTrue(viewModel.uiState.value.records.isEmpty())
        assertFalse(viewModel.uiState.value.isLoading)
    }

    class FakeCalendarRecordRepository : CalendarRecordRepository {
        val flow = MutableSharedFlow<List<CalendarRecord>>()
        override fun getRecordsStream(year: Int, month: Int): Flow<List<CalendarRecord>> {
            return flow
        }

        var year: Int = 0
        var month: Int = 0
        override suspend fun refreshRecords(year: Int, month: Int) {
            this.year = year
            this.month = month
        }

        override suspend fun getRecord(year: Int, month: Int, day: Int): CalendarRecord {
            return CalendarRecord(Date(), listOf())
        }
        override suspend fun updateRecord(record: CalendarRecord) {}
    }
}