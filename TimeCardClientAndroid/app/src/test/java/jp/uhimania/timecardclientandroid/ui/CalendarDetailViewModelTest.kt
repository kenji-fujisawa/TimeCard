package jp.uhimania.timecardclientandroid.ui

import androidx.lifecycle.SavedStateHandle
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.TimeRecord
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Date

class CalendarDetailViewModelTest {
    @OptIn(ExperimentalCoroutinesApi::class)
    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testAddTimeRecord() = runTest(UnconfinedTestDispatcher()) {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val repository = FakeCalendarRecordRepository()
        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)
        assertEquals(0, viewModel.uiState.value.records.count())

        viewModel.onEvent(CalendarDetailUiEvent.AddTimeRecord)
        assertEquals(1, viewModel.uiState.value.records.count())
        assertEquals(viewModel.uiState.value.date, viewModel.uiState.value.records[0].checkIn)
        assertEquals(viewModel.uiState.value.date, viewModel.uiState.value.records[0].checkOut)

        viewModel.onEvent(CalendarDetailUiEvent.AddTimeRecord)
        assertEquals(2, viewModel.uiState.value.records.count())
        assertEquals(viewModel.uiState.value.date, viewModel.uiState.value.records[1].checkIn)
        assertEquals(viewModel.uiState.value.date, viewModel.uiState.value.records[1].checkOut)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testUpdateTimeRecord() = runTest(UnconfinedTestDispatcher()) {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val date = Date()
        val record1 = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 60),
            checkOut = Date(date.time + 120)
        )
        val record2 = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 180),
            checkOut = Date(date.time + 240)
        )

        val repository = FakeCalendarRecordRepository()
        repository.records = listOf(record1.asTimeRecord(), record2.asTimeRecord())

        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)

        viewModel.onEvent(CalendarDetailUiEvent.UpdateTimeRecord(
            id = "id",
            checkIn = Date(),
            checkOut = Date()
        ))
        assertEquals(2, viewModel.uiState.value.records.count())
        assertEquals(record1.checkIn, viewModel.uiState.value.records[0].checkIn)
        assertEquals(record1.checkOut, viewModel.uiState.value.records[0].checkOut)
        assertEquals(record2.checkIn, viewModel.uiState.value.records[1].checkIn)
        assertEquals(record2.checkOut, viewModel.uiState.value.records[1].checkOut)

        val date1 = Date(date.time + 90)
        viewModel.onEvent(CalendarDetailUiEvent.UpdateTimeRecord(
            id = record1.id,
            checkIn = date1,
            checkOut = record1.checkOut
        ))
        assertEquals(2, viewModel.uiState.value.records.count())
        assertEquals(date1, viewModel.uiState.value.records[0].checkIn)
        assertEquals(record1.checkOut, viewModel.uiState.value.records[0].checkOut)
        assertEquals(record2.checkIn, viewModel.uiState.value.records[1].checkIn)
        assertEquals(record2.checkOut, viewModel.uiState.value.records[1].checkOut)

        val date2 = Date(date.time + 300)
        viewModel.onEvent(CalendarDetailUiEvent.UpdateTimeRecord(
            id = record2.id,
            checkIn = record2.checkIn,
            checkOut = date2
        ))
        assertEquals(2, viewModel.uiState.value.records.count())
        assertEquals(date1, viewModel.uiState.value.records[0].checkIn)
        assertEquals(record1.checkOut, viewModel.uiState.value.records[0].checkOut)
        assertEquals(record2.checkIn, viewModel.uiState.value.records[1].checkIn)
        assertEquals(date2, viewModel.uiState.value.records[1].checkOut)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testRemoveTimeRecord() = runTest(UnconfinedTestDispatcher()) {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val date = Date()
        val record1 = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 60),
            checkOut = Date(date.time + 120)
        )
        val record2 = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 180),
            checkOut = Date(date.time + 240)
        )

        val repository = FakeCalendarRecordRepository()
        repository.records = listOf(record1.asTimeRecord(), record2.asTimeRecord())

        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)

        viewModel.onEvent(CalendarDetailUiEvent.RemoveTimeRecord("id"))
        assertEquals(2, viewModel.uiState.value.records.count())
        assertEquals(record1.id, viewModel.uiState.value.records[0].id)
        assertEquals(record2.id, viewModel.uiState.value.records[1].id)

        viewModel.onEvent(CalendarDetailUiEvent.RemoveTimeRecord(record2.id))
        assertEquals(1, viewModel.uiState.value.records.count())
        assertEquals(record1.id, viewModel.uiState.value.records[0].id)

        viewModel.onEvent(CalendarDetailUiEvent.RemoveTimeRecord(record1.id))
        assertEquals(0, viewModel.uiState.value.records.count())
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testAddBreakTime() = runTest(UnconfinedTestDispatcher()) {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val date = Date()
        val record = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 60),
            checkOut = Date(date.time + 120)
        )

        val repository = FakeCalendarRecordRepository()
        repository.records = listOf(record.asTimeRecord())

        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)

        viewModel.onEvent(CalendarDetailUiEvent.AddBreakTime("id"))
        assertEquals(0, viewModel.uiState.value.records[0].breakTimes.count())

        viewModel.onEvent(CalendarDetailUiEvent.AddBreakTime(record.id))
        assertEquals(1, viewModel.uiState.value.records[0].breakTimes.count())
        assertEquals(record.checkIn, viewModel.uiState.value.records[0].breakTimes[0].start)
        assertEquals(record.checkIn, viewModel.uiState.value.records[0].breakTimes[0].end)

        viewModel.onEvent(CalendarDetailUiEvent.AddBreakTime(record.id))
        assertEquals(2, viewModel.uiState.value.records[0].breakTimes.count())
        assertEquals(record.checkIn, viewModel.uiState.value.records[0].breakTimes[1].start)
        assertEquals(record.checkIn, viewModel.uiState.value.records[0].breakTimes[1].end)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testUpdateBreakTime() = runTest(UnconfinedTestDispatcher()) {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val date = Date()
        val breakTime1 = CalendarDetailUiState.BreakTime(
            start = Date(date.time + 60),
            end = Date(date.time + 120)
        )
        val breakTime2 = CalendarDetailUiState.BreakTime(
            start = Date(date.time + 180),
            end = Date(date.time + 240)
        )
        val record = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 0),
            checkOut = Date(date.time + 300),
            breakTimes = listOf(breakTime1, breakTime2)
        )

        val repository = FakeCalendarRecordRepository()
        repository.records = listOf(record.asTimeRecord())

        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)

        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = "id",
            breakTimeId = breakTime1.id,
            start = Date(),
            end = Date()
        ))
        assertEquals(breakTime1.start, viewModel.uiState.value.records[0].breakTimes[0].start)
        assertEquals(breakTime1.end, viewModel.uiState.value.records[0].breakTimes[0].end)
        assertEquals(breakTime2.start, viewModel.uiState.value.records[0].breakTimes[1].start)
        assertEquals(breakTime2.end, viewModel.uiState.value.records[0].breakTimes[1].end)

        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = record.id,
            breakTimeId = "id",
            start = Date(),
            end = Date()
        ))
        assertEquals(breakTime1.start, viewModel.uiState.value.records[0].breakTimes[0].start)
        assertEquals(breakTime1.end, viewModel.uiState.value.records[0].breakTimes[0].end)
        assertEquals(breakTime2.start, viewModel.uiState.value.records[0].breakTimes[1].start)
        assertEquals(breakTime2.end, viewModel.uiState.value.records[0].breakTimes[1].end)

        val date1 = Date(date.time + 90)
        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = record.id,
            breakTimeId = breakTime1.id,
            start = date1,
            end = breakTime1.end
        ))
        assertEquals(date1, viewModel.uiState.value.records[0].breakTimes[0].start)
        assertEquals(breakTime1.end, viewModel.uiState.value.records[0].breakTimes[0].end)
        assertEquals(breakTime2.start, viewModel.uiState.value.records[0].breakTimes[1].start)
        assertEquals(breakTime2.end, viewModel.uiState.value.records[0].breakTimes[1].end)

        val date2 = Date(date.time + 270)
        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = record.id,
            breakTimeId = breakTime2.id,
            start = breakTime2.start,
            end = date2
        ))
        assertEquals(date1, viewModel.uiState.value.records[0].breakTimes[0].start)
        assertEquals(breakTime1.end, viewModel.uiState.value.records[0].breakTimes[0].end)
        assertEquals(breakTime2.start, viewModel.uiState.value.records[0].breakTimes[1].start)
        assertEquals(date2, viewModel.uiState.value.records[0].breakTimes[1].end)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testRemoveBreakTime() = runTest(UnconfinedTestDispatcher()) {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val date = Date()
        val breakTime1 = CalendarDetailUiState.BreakTime(
            start = Date(date.time + 60),
            end = Date(date.time + 120)
        )
        val breakTime2 = CalendarDetailUiState.BreakTime(
            start = Date(date.time + 180),
            end = Date(date.time + 240)
        )
        val record = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 0),
            checkOut = Date(date.time + 300),
            breakTimes = listOf(breakTime1, breakTime2)
        )

        val repository = FakeCalendarRecordRepository()
        repository.records = listOf(record.asTimeRecord())

        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)

        viewModel.onEvent(CalendarDetailUiEvent.RemoveBreakTime("id", breakTime1.id))
        assertEquals(2, viewModel.uiState.value.records[0].breakTimes.count())
        assertEquals(breakTime1.id, viewModel.uiState.value.records[0].breakTimes[0].id)
        assertEquals(breakTime2.id, viewModel.uiState.value.records[0].breakTimes[1].id)

        viewModel.onEvent(CalendarDetailUiEvent.RemoveBreakTime(record.id, "id"))
        assertEquals(2, viewModel.uiState.value.records[0].breakTimes.count())
        assertEquals(breakTime1.id, viewModel.uiState.value.records[0].breakTimes[0].id)
        assertEquals(breakTime2.id, viewModel.uiState.value.records[0].breakTimes[1].id)

        viewModel.onEvent(CalendarDetailUiEvent.RemoveBreakTime(record.id, breakTime1.id))
        assertEquals(1, viewModel.uiState.value.records[0].breakTimes.count())
        assertEquals(breakTime2.id, viewModel.uiState.value.records[0].breakTimes[0].id)

        viewModel.onEvent(CalendarDetailUiEvent.RemoveBreakTime(record.id, breakTime2.id))
        assertEquals(0, viewModel.uiState.value.records[0].breakTimes.count())
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testValidateTimeRecord_order() = runTest(UnconfinedTestDispatcher()) {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val date = Date()
        val record = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 60),
            checkOut = Date(date.time + 120)
        )

        val repository = FakeCalendarRecordRepository()
        repository.records = listOf(record.asTimeRecord())

        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)

        // not changed
        assertFalse(viewModel.uiState.value.valid)
        assertTrue(viewModel.uiState.value.records[0].valid)

        // reversed checkIn and checkOut
        viewModel.onEvent(CalendarDetailUiEvent.UpdateTimeRecord(
            id = record.id,
            checkIn = Date(date.time + 120),
            checkOut = Date(date.time + 60)
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertFalse(viewModel.uiState.value.records[0].valid)

        // ok
        viewModel.onEvent(CalendarDetailUiEvent.UpdateTimeRecord(
            id = record.id,
            checkIn = Date(date.time + 30),
            checkOut = record.checkOut
        ))
        assertTrue(viewModel.uiState.value.valid)
        assertTrue(viewModel.uiState.value.records[0].valid)

        // before minimum date
        viewModel.onEvent(CalendarDetailUiEvent.UpdateTimeRecord(
            id = record.id,
            checkIn = Date(date.time - 60),
            checkOut = record.checkOut
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertFalse(viewModel.uiState.value.records[0].valid)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testValidateTimeRecord_overlap() = runTest(UnconfinedTestDispatcher()) {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val date = Date()
        val record1 = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 30),
            checkOut = Date(date.time + 120)
        )
        val record2 = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 180),
            checkOut = Date(date.time + 240)
        )
        val record3 = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 90),
            checkOut = Date(date.time + 210)
        )

        val repository = FakeCalendarRecordRepository()
        repository.records = listOf(record1.asTimeRecord(), record2.asTimeRecord())

        val handle = SavedStateHandle()
        var viewModel = CalendarDetailViewModel(repository, handle)

        // not changed
        assertFalse(viewModel.uiState.value.valid)
        assertTrue(viewModel.uiState.value.records[0].valid)
        assertTrue(viewModel.uiState.value.records[1].valid)

        // ok
        viewModel.onEvent(CalendarDetailUiEvent.UpdateTimeRecord(
            id = record1.id,
            checkIn = Date(date.time + 60),
            checkOut = record1.checkOut
        ))
        assertTrue(viewModel.uiState.value.valid)
        assertTrue(viewModel.uiState.value.records[0].valid)
        assertTrue(viewModel.uiState.value.records[1].valid)

        // overlap all
        repository.records = listOf(record1.asTimeRecord(), record2.asTimeRecord(), record3.asTimeRecord())
        viewModel = CalendarDetailViewModel(repository, handle)
        viewModel.onEvent(CalendarDetailUiEvent.UpdateTimeRecord(
            id = record1.id,
            checkIn = Date(date.time + 60),
            checkOut = record1.checkOut
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertFalse(viewModel.uiState.value.records[0].valid)
        assertFalse(viewModel.uiState.value.records[1].valid)
        assertFalse(viewModel.uiState.value.records[2].valid)

        // overlap 1 and 3
        viewModel.onEvent(CalendarDetailUiEvent.UpdateTimeRecord(
            id = record3.id,
            checkIn = record3.checkIn,
            checkOut = Date(date.time + 120)
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertFalse(viewModel.uiState.value.records[0].valid)
        assertTrue(viewModel.uiState.value.records[1].valid)
        assertFalse(viewModel.uiState.value.records[2].valid)

        // overlap 2 and 3
        viewModel.onEvent(CalendarDetailUiEvent.UpdateTimeRecord(
            id = record3.id,
            checkIn = Date(date.time + 180),
            checkOut = Date(date.time + 210)
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertTrue(viewModel.uiState.value.records[0].valid)
        assertFalse(viewModel.uiState.value.records[1].valid)
        assertFalse(viewModel.uiState.value.records[2].valid)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testValidateBreakTime_order() = runTest(UnconfinedTestDispatcher()) {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val date = Date()
        val breakTime = CalendarDetailUiState.BreakTime(
            start = Date(date.time + 120),
            end = Date(date.time + 180)
        )
        val timeRecord = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 60),
            checkOut = Date(date.time + 240),
            breakTimes = listOf(breakTime)
        )

        val repository = FakeCalendarRecordRepository()
        repository.records = listOf(timeRecord.asTimeRecord())

        val handle = SavedStateHandle()
        val viewModel = CalendarDetailViewModel(repository, handle)

        // not changed
        assertFalse(viewModel.uiState.value.valid)
        assertTrue(viewModel.uiState.value.records[0].breakTimes[0].valid)

        // reversed start and end
        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = timeRecord.id,
            breakTimeId = breakTime.id,
            start = Date(date.time + 180),
            end = Date(date.time + 120)
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertFalse(viewModel.uiState.value.records[0].breakTimes[0].valid)

        // ok
        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = timeRecord.id,
            breakTimeId = breakTime.id,
            start = Date(date.time + 90),
            end = breakTime.end
        ))
        assertTrue(viewModel.uiState.value.valid)
        assertTrue(viewModel.uiState.value.records[0].breakTimes[0].valid)

        // before checkIn
        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = timeRecord.id,
            breakTimeId = breakTime.id,
            start = Date(date.time + 30),
            end = breakTime.end
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertFalse(viewModel.uiState.value.records[0].breakTimes[0].valid)

        // after checkOut
        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = timeRecord.id,
            breakTimeId = breakTime.id,
            start = Date(date.time + 90),
            end = Date(date.time + 270)
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertFalse(viewModel.uiState.value.records[0].breakTimes[0].valid)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testValidateBreakTime_overlap() = runTest(UnconfinedTestDispatcher()) {
        Dispatchers.setMain(UnconfinedTestDispatcher())

        val date = Date()
        val breakTime1 = CalendarDetailUiState.BreakTime(
            start = Date(date.time + 90),
            end = Date(date.time + 180)
        )
        val breakTime2 = CalendarDetailUiState.BreakTime(
            start = Date(date.time + 240),
            end = Date(date.time + 300)
        )
        val breakTime3 = CalendarDetailUiState.BreakTime(
            start = Date(date.time + 150),
            end = Date(date.time + 270)
        )

        var timeRecord = CalendarDetailUiState.TimeRecord(
            checkIn = Date(date.time + 60),
            checkOut = Date(date.time + 360),
            breakTimes = listOf(breakTime1, breakTime2)
        )

        val repository = FakeCalendarRecordRepository()
        repository.records = listOf(timeRecord.asTimeRecord())

        val handle = SavedStateHandle()
        var viewModel = CalendarDetailViewModel(repository, handle)

        // not changed
        assertFalse(viewModel.uiState.value.valid)
        assertTrue(viewModel.uiState.value.records[0].breakTimes[0].valid)
        assertTrue(viewModel.uiState.value.records[0].breakTimes[1].valid)

        // ok
        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = timeRecord.id,
            breakTimeId = breakTime1.id,
            start = Date(date.time + 120),
            end = breakTime1.end
        ))
        assertTrue(viewModel.uiState.value.valid)
        assertTrue(viewModel.uiState.value.records[0].breakTimes[0].valid)
        assertTrue(viewModel.uiState.value.records[0].breakTimes[1].valid)

        // overlap all
        timeRecord = timeRecord.copy(breakTimes = listOf(breakTime1, breakTime2, breakTime3))
        repository.records = listOf(timeRecord.asTimeRecord())
        viewModel = CalendarDetailViewModel(repository, handle)
        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = timeRecord.id,
            breakTimeId = breakTime1.id,
            start = Date(date.time + 120),
            end = breakTime1.end
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertFalse(viewModel.uiState.value.records[0].breakTimes[0].valid)
        assertFalse(viewModel.uiState.value.records[0].breakTimes[1].valid)
        assertFalse(viewModel.uiState.value.records[0].breakTimes[2].valid)

        // overlap 1 and 3
        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = timeRecord.id,
            breakTimeId = breakTime3.id,
            start = breakTime3.start,
            end = Date(date.time + 180)
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertFalse(viewModel.uiState.value.records[0].breakTimes[0].valid)
        assertTrue(viewModel.uiState.value.records[0].breakTimes[1].valid)
        assertFalse(viewModel.uiState.value.records[0].breakTimes[2].valid)

        // overlap 2 and 3
        viewModel.onEvent(CalendarDetailUiEvent.UpdateBreakTime(
            timeRecordId = timeRecord.id,
            breakTimeId = breakTime3.id,
            start = Date(date.time + 240),
            end = Date(date.time + 270)
        ))
        assertFalse(viewModel.uiState.value.valid)
        assertTrue(viewModel.uiState.value.records[0].breakTimes[0].valid)
        assertFalse(viewModel.uiState.value.records[0].breakTimes[1].valid)
        assertFalse(viewModel.uiState.value.records[0].breakTimes[2].valid)
    }

    class FakeCalendarRecordRepository : CalendarRecordRepository {
        override fun getRecordsStream(year: Int, month: Int): Flow<List<CalendarRecord>> {
            return flowOf()
        }

        override suspend fun refreshRecords(year: Int, month: Int) {}

        var records: List<TimeRecord> = listOf()
        override suspend fun getRecord(year: Int, month: Int, day: Int): CalendarRecord {
            return CalendarRecord(Date(), records)
        }

        override suspend fun updateRecord(record: CalendarRecord) {}
    }
}