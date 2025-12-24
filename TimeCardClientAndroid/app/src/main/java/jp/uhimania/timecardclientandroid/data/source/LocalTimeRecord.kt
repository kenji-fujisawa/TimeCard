package jp.uhimania.timecardclientandroid.data.source

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date

@Entity(
    tableName = "break_times",
    foreignKeys = [
        ForeignKey(
            entity = LocalTimeRecord::class,
            parentColumns = ["id"],
            childColumns = ["timeRecordId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class LocalBreakTime(
    @PrimaryKey val id: String = "",
    val start: Date?,
    val end: Date?,
    val timeRecordId: String
)

@Entity(tableName = "time_records", indices = [Index(value = ["year", "month"])])
data class LocalTimeRecord(
    @PrimaryKey val id: String = "",
    val year: Int,
    val month: Int,
    val checkIn: Date?,
    val checkOut: Date?
)
