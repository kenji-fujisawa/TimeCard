package jp.uhimania.timecardclientandroid

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.ui.Modifier
import jp.uhimania.timecardclientandroid.ui.TimeCardView
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TimeCardClientAndroidTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    TimeCardView(
                        modifier = Modifier.padding(innerPadding)
                    )
                }
            }
        }
    }
}
