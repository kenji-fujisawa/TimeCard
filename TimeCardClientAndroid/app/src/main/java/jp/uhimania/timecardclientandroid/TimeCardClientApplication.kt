package jp.uhimania.timecardclientandroid

import android.app.Application
import jp.uhimania.timecardclientandroid.data.source.LocalDataSource
import jp.uhimania.timecardclientandroid.data.source.LocalDatabase
import jp.uhimania.timecardclientandroid.data.source.NetworkDataSource
import jp.uhimania.timecardclientandroid.data.source.RetrofitNetworkDataSource
import okhttp3.HttpUrl

class TimeCardClientApplication : Application() {
    lateinit var networkDataSource: NetworkDataSource
    lateinit var localDataSource: LocalDataSource

    override fun onCreate() {
        super.onCreate()

        val url = HttpUrl.Builder()
            .scheme("http")
            .host("192.168.4.33")
            .port(8080)
            .build()
        networkDataSource = RetrofitNetworkDataSource(url)

        localDataSource = LocalDatabase.getDatabase(this).dataSource()
    }
}