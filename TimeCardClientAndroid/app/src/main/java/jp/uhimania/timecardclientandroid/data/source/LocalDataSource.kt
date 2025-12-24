package jp.uhimania.timecardclientandroid.data.source

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import androidx.room.Update
import kotlinx.coroutines.flow.Flow
import java.util.Date

@Dao
interface LocalDataSource {
    @Query("""
        SELECT              *
        FROM                time_records t
        LEFT OUTER JOIN     break_times b
        ON                  t.id = b.timeRecordId
        WHERE               t.year = :year
        AND                 t.month = :month
        ORDER BY            t.checkIn, b.start
    """)
    fun getRecords(year: Int, month: Int): Flow<Map<LocalTimeRecord, List<LocalBreakTime>>>

    @Query("DELETE FROM time_records WHERE year = :year AND month = :month")
    fun deleteRecords(year: Int, month: Int)

    @Query("SELECT * FROM time_records ORDER BY checkIn")
    fun getTimeRecords(): Flow<List<LocalTimeRecord>>

    @Query("SELECT * FROM break_times ORDER BY start")
    fun getBreakTimes(): Flow<List<LocalBreakTime>>

    @Insert suspend fun insert(record: LocalTimeRecord)
    @Insert suspend fun insert(breakTime: LocalBreakTime)

    @Update suspend fun update(record: LocalTimeRecord)
    @Update suspend fun update(breakTime: LocalBreakTime)

    @Delete suspend fun delete(record: LocalTimeRecord)
    @Delete suspend fun delete(breakTime: LocalBreakTime)
}

@Database(entities = [LocalTimeRecord::class, LocalBreakTime::class], version = 1)
@TypeConverters(DateConverter::class)
abstract class LocalDatabase : RoomDatabase() {
    abstract fun dataSource(): LocalDataSource

    companion object {
        @Volatile private var instance: LocalDatabase? = null

        fun getDatabase(context: Context): LocalDatabase {
            return instance ?: synchronized(this) {
                Room.databaseBuilder(context, LocalDatabase::class.java, "TimeCard.db")
                    .build()
                    .also { instance = it }
            }
        }
    }
}

class DateConverter {
    @TypeConverter
    fun from(value: Long): Date {
        return Date(value)
    }

    @TypeConverter
    fun to(value: Date): Long {
        return value.time
    }
}
