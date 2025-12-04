package jp.uhimania.timecardclientandroid.data.source

import kotlinx.coroutines.test.runTest
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import retrofit2.HttpException
import java.text.SimpleDateFormat
import java.util.Date

class RetrofitNetworkDataSourceTest {
    private lateinit var mockServer: MockWebServer

    @Before
    fun setup() {
        mockServer = MockWebServer()
        mockServer.start()
    }

    @After
    fun teardown() {
        mockServer.shutdown()
    }

    @Test
    fun testGetRecords_success() = runTest {
        val response = MockResponse()
            .setResponseCode(200)
            .setBody(
                """
                    [
                        {
                            "id":"1B97D98D-A71E-4E57-B631-20F9AD492624",
                            "year":2025,
                            "month":12,
                            "checkIn":786242897.725608,
                            "checkOut":786277228.928412,
                            "breakTimes":[
                                {
                                    "id":"A92129DB-92B8-4057-A5CC-D965D9664B35",
                                    "start":786252677.725608,
                                    "end":786255737.725608
                                }
                            ]
                        },
                        {
                            "id":"4D1A3B51-D16F-486A-93FC-85C231DDACAD",
                            "year":2025,
                            "month":12,
                            "checkIn":786328648.080071,
                            "checkOut":786361916.853093,
                            "breakTimes":[
                                {
                                    "id":"B85CDC50-C796-4A9D-AD95-46FFD1D8EA13",
                                    "start":786339206.024485,
                                    "end":786342090.21777
                                }
                            ]
                        }
                    ]
                """.trimIndent()
            )
        mockServer.enqueue(response)

        val source = RetrofitNetworkDataSource(mockServer.url(""))
        val records = source.getRecords(2025, 12)
        assertEquals(2, records.count())

        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm")
        assertEquals("2025-12-01 09:48", formatter.format(records[0].checkIn ?: Date()))
        assertEquals("2025-12-01 19:20", formatter.format(records[0].checkOut ?: Date()))

        assertEquals(1, records[0].breakTimes.count())
        assertEquals("2025-12-01 12:31", formatter.format(records[0].breakTimes[0].start ?: Date()))
        assertEquals("2025-12-01 13:22", formatter.format(records[0].breakTimes[0].end ?: Date()))

        assertEquals("2025-12-02 09:37", formatter.format(records[1].checkIn ?: Date()))
        assertEquals("2025-12-02 18:51", formatter.format(records[1].checkOut ?: Date()))

        assertEquals(1, records[1].breakTimes.count())
        assertEquals("2025-12-02 12:33", formatter.format(records[1].breakTimes[0].start ?: Date()))
        assertEquals("2025-12-02 13:21", formatter.format(records[1].breakTimes[0].end ?: Date()))
    }

    @Test(expected = HttpException::class)
    fun testGetRecords_fail() = runTest {
        val response = MockResponse().setResponseCode(404)
        mockServer.enqueue(response)

        val source = RetrofitNetworkDataSource(mockServer.url(""))
        source.getRecords(2025, 12)
    }
}