package jp.uhimania.timecardclientandroid

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import jp.uhimania.timecardclientandroid.ui.TimeCardView
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TimeCardClientAndroidTheme {
                TimeCardView()
            }
        }
    }
}
