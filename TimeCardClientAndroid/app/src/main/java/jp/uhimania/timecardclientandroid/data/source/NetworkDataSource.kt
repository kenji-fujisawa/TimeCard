package jp.uhimania.timecardclientandroid.data.source

import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import jp.uhimania.timecardclientandroid.data.TimeRecord
import kotlinx.serialization.json.Json
import okhttp3.HttpUrl
import okhttp3.MediaType.Companion.toMediaType
import retrofit2.Retrofit
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

interface NetworkDataSource {
    suspend fun getRecords(year: Int, month: Int): List<TimeRecord>
    suspend fun insertRecord(record: TimeRecord): TimeRecord
    suspend fun updateRecord(record: TimeRecord): TimeRecord
    suspend fun deleteRecord(record: TimeRecord)
}

class RetrofitNetworkDataSource(private val baseUrl: HttpUrl) : NetworkDataSource {
    private val json = Json { ignoreUnknownKeys = true }

    private val retrofit = Retrofit.Builder()
        .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
        .baseUrl(baseUrl)
        .build()

    private val service: TimeCardApiService by lazy {
        retrofit.create(TimeCardApiService::class.java)
    }

    override suspend fun getRecords(year: Int, month: Int): List<TimeRecord> {
        return service.getRecords(year, month)
    }

    override suspend fun insertRecord(record: TimeRecord): TimeRecord {
        return service.insertRecord(record)[0]
    }

    override suspend fun updateRecord(record: TimeRecord): TimeRecord {
        return service.updateRecord(record.id, record)[0]
    }

    override suspend fun deleteRecord(record: TimeRecord) {
        service.deleteRecord(record.id)
    }
}

interface TimeCardApiService {
    @GET("timecard/records")
    suspend fun getRecords(
        @Query("year") year: Int,
        @Query("month") month: Int
    ): List<TimeRecord>

    @POST("timecard/records")
    suspend fun insertRecord(
        @Body record: TimeRecord
    ): List<TimeRecord>

    @PATCH("timecard/records/{id}")
    suspend fun updateRecord(
        @Path("id") id: String,
        @Body record: TimeRecord
    ): List<TimeRecord>

    @DELETE("timecard/records/{id}")
    suspend fun deleteRecord(
        @Path("id") id: String
    )
}
