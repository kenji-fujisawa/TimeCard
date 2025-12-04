package jp.uhimania.timecardclientandroid.data.source

import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import jp.uhimania.timecardclientandroid.data.TimeRecord
import kotlinx.serialization.json.Json
import okhttp3.HttpUrl
import okhttp3.MediaType.Companion.toMediaType
import retrofit2.Retrofit
import retrofit2.http.GET
import retrofit2.http.Query

interface NetworkDataSource {
    suspend fun getRecords(year: Int, month: Int): List<TimeRecord>
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
}

interface TimeCardApiService {
    @GET("timecard/records")
    suspend fun getRecords(
        @Query("year") year: Int,
        @Query("month") month: Int
    ): List<TimeRecord>
}
