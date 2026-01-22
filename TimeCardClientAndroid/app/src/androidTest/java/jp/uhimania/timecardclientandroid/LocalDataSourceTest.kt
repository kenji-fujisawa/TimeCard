package jp.uhimania.timecardclientandroid

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import jp.uhimania.timecardclientandroid.data.source.LocalBreakTime
import jp.uhimania.timecardclientandroid.data.source.LocalDataSource
import jp.uhimania.timecardclientandroid.data.source.LocalDatabase
import jp.uhimania.timecardclientandroid.data.source.LocalTimeRecord
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.text.SimpleDateFormat

class LocalDataSourceTest {
    private lateinit var dataSource: LocalDataSource
    private lateinit var database: LocalDatabase

    private val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
    private val records = listOf(
        LocalTimeRecord(
            id = "1",
            year = 2025,
            month = 12,
            checkIn = formatter.parse("2025-12-22 09:12:38"),
            checkOut = formatter.parse("2025-12-22 18:45:29")
        ),
        LocalTimeRecord(
            id = "2",
            year = 2025,
            month = 12,
            checkIn = formatter.parse("2025-12-22 22:02:18"),
            checkOut = formatter.parse("2025-12-22 23:45:40")
        ),
        LocalTimeRecord(
            id = "3",
            year = 2025,
            month = 11,
            checkIn = formatter.parse("2025-11-15 08:50:11"),
            checkOut = formatter.parse("2025-11-15 19:05:20")
        )
    )
    private val breakTimes = listOf(
        LocalBreakTime(
            id = "1",
            start = formatter.parse("2025-12-22 12:30:45"),
            end = formatter.parse("2025-12-22 13:14:22"),
            timeRecordId = "1"
        ),
        LocalBreakTime(
            id = "2",
            start = formatter.parse("2025-11-15 12:29:08"),
            end = formatter.parse("2025-11-15 13:20:12"),
            timeRecordId = "3"
        ),
        LocalBreakTime(
            id = "3",
            start = formatter.parse("2025-11-15 15:03:44"),
            end = formatter.parse("2025-11-15 15:32:58"),
            timeRecordId = "3"
        )
    )

    @Before
    fun setup() {
        val context: Context = ApplicationProvider.getApplicationContext()
        database = Room.inMemoryDatabaseBuilder(context, LocalDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        dataSource = database.dataSource()
    }

    @After
    fun teardown() {
        database.close()
    }

    @Test
    fun testInsert() = runBlocking {
        records.forEach { dataSource.insert(it) }
        breakTimes.forEach { dataSource.insert(it) }

        val recs = dataSource.getTimeRecords().first()
        assertEquals(3, recs.count())
        assertEquals(records[2], recs[0])
        assertEquals(records[0], recs[1])
        assertEquals(records[1], recs[2])

        val breaks = dataSource.getBreakTimes().first()
        assertEquals(3, breaks.count())
        assertEquals(breakTimes[1], breaks[0])
        assertEquals(breakTimes[2], breaks[1])
        assertEquals(breakTimes[0], breaks[2])
    }

    @Test
    fun testUpdate() = runBlocking {
        records.forEach { dataSource.insert(it) }
        breakTimes.forEach { dataSource.insert(it) }

        val record = records[0].copy(checkOut = formatter.parse("2025-12-22 19:28:33"))
        dataSource.update(record)

        val breakTime = breakTimes[0].copy(start = formatter.parse("2025-12-22 11:58:14"))
        dataSource.update(breakTime)

        val recs = dataSource.getTimeRecords().first()
        assertEquals(3, recs.count())
        assertEquals(records[2], recs[0])
        assertEquals(record, recs[1])
        assertEquals(records[1], recs[2])

        val breaks = dataSource.getBreakTimes().first()
        assertEquals(3, breaks.count())
        assertEquals(breakTimes[1], breaks[0])
        assertEquals(breakTimes[2], breaks[1])
        assertEquals(breakTime, breaks[2])
    }

    @Test
    fun testDelete() = runBlocking {
        records.forEach { dataSource.insert(it) }
        breakTimes.forEach { dataSource.insert(it) }

        dataSource.delete(records[0])
        dataSource.delete(breakTimes[1])

        val recs = dataSource.getTimeRecords().first()
        assertEquals(2, recs.count())
        assertEquals(records[2], recs[0])
        assertEquals(records[1], recs[1])

        val breaks = dataSource.getBreakTimes().first()
        assertEquals(1, breaks.count())
        assertEquals(breakTimes[2], breaks[0])
    }

    @Test
    fun testGetRecords() = runBlocking {
        records.forEach { dataSource.insert(it) }
        breakTimes.forEach { dataSource.insert(it) }

        var recs = dataSource.getRecords(2025, 12).first()
        assertEquals(2, recs.count())

        assertTrue(recs.keys.contains(records[0]))
        assertEquals(1, recs[records[0]]?.count())
        assertEquals(breakTimes[0], recs[records[0]]?.get(0))

        assertTrue(recs.keys.contains(records[1]))
        assertEquals(0, recs[records[1]]?.count())

        recs = dataSource.getRecords(2025, 11).first()
        assertEquals(1, recs.count())

        assertTrue(recs.keys.contains(records[2]))
        assertEquals(2, recs[records[2]]?.count())
        assertEquals(breakTimes[1], recs[records[2]]?.get(0))
        assertEquals(breakTimes[2], recs[records[2]]?.get(1))

        recs = dataSource.getRecords(2025, 10).first()
        assertEquals(0, recs.count())
    }

    @Test
    fun testDeleteRecords() = runBlocking {
        records.forEach { dataSource.insert(it) }
        breakTimes.forEach { dataSource.insert(it) }

        dataSource.deleteRecords(2025, 12)

        val recs = dataSource.getTimeRecords().first()
        assertEquals(1, recs.count())
        assertEquals(records[2], recs[0])

        val breaks = dataSource.getBreakTimes().first()
        assertEquals(2, breaks.count())
        assertEquals(breakTimes[1], breaks[0])
        assertEquals(breakTimes[2], breaks[1])
    }
}
