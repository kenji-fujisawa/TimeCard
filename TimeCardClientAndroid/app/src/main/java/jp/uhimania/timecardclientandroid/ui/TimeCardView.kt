package jp.uhimania.timecardclientandroid.ui

import android.annotation.SuppressLint
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import jp.uhimania.timecardclientandroid.data.CalendarRecord
import jp.uhimania.timecardclientandroid.data.CalendarRecordRepository
import jp.uhimania.timecardclientandroid.data.datesOf
import jp.uhimania.timecardclientandroid.ui.NavigationArgs.DATE_ARG
import jp.uhimania.timecardclientandroid.ui.NavigationRoutes.CALENDAR_DETAIL_ROUTE
import jp.uhimania.timecardclientandroid.ui.NavigationRoutes.CALENDAR_ROUTE
import jp.uhimania.timecardclientandroid.ui.NavigationViews.CALENDAR_DETAIL_VIEW
import jp.uhimania.timecardclientandroid.ui.NavigationViews.CALENDAR_VIEW
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import java.util.Calendar
import java.util.Date

object NavigationViews {
    const val CALENDAR_VIEW = "calendar"
    const val CALENDAR_DETAIL_VIEW = "detail"
}

object NavigationArgs {
    const val DATE_ARG = "date"
}

object NavigationRoutes {
    const val CALENDAR_ROUTE = CALENDAR_VIEW
    const val CALENDAR_DETAIL_ROUTE = "$CALENDAR_DETAIL_VIEW/{$DATE_ARG}"
}

@Composable
fun TimeCardView(
    modifier: Modifier = Modifier,
    navController: NavHostController = rememberNavController(),
    viewModel: CalendarViewModel = viewModel(factory = CalendarViewModel.Factory),
    snackbarHostState: SnackbarHostState = remember { SnackbarHostState() }
) {
    Scaffold(
        modifier = Modifier.fillMaxSize(),
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { innerPadding ->
        val uiState by viewModel.uiState.collectAsState()
        if (uiState.isLoading) {
            LoadingView(
                modifier = modifier
                    .fillMaxSize()
                    .padding(innerPadding)
            )
        } else {
            NavHost(
                navController = navController,
                startDestination = CALENDAR_ROUTE,
                modifier = modifier.padding(innerPadding)
            ) {
                composable(CALENDAR_ROUTE) {
                    CalendarView(
                        date = uiState.date,
                        records = uiState.records,
                        onDateChange = { viewModel.updateDate(it) },
                        onDateSelect = { navController.navigate("$CALENDAR_DETAIL_VIEW/${it.time}") }
                    )
                }
                composable(
                    route = CALENDAR_DETAIL_ROUTE,
                    arguments = listOf(
                        navArgument(DATE_ARG) { type = NavType.LongType }
                    )
                ) {
                    CalendarDetailView(
                        onBack = {
                            navController.popBackStack()
                        }
                    )
                }
            }

            uiState.message?.let { 
                val message = stringResource(it)
                LaunchedEffect(snackbarHostState, viewModel, message) {
                    snackbarHostState.showSnackbar(message)
                    viewModel.messageShown()
                }
            }
        }
    }
}

@Composable
private fun LoadingView(
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}

@SuppressLint("ViewModelConstructorInComposable")
@Preview(showBackground = true)
@Composable
private fun TimeCardViewPreview() {
    class FakeCalendarRecordRepository : CalendarRecordRepository {
        override fun getRecordsStream(year: Int, month: Int): Flow<List<CalendarRecord>> {
            val records = Calendar.getInstance().datesOf(year, month).map {
                CalendarRecord(it, listOf())
            }
            return flowOf(records)
        }

        override suspend fun getRecord(year: Int, month: Int, day: Int): CalendarRecord {
            return CalendarRecord(Date(), listOf())
        }
        override suspend fun updateRecord(record: CalendarRecord) {}
    }

    TimeCardClientAndroidTheme {
        val vm = CalendarViewModel(FakeCalendarRecordRepository())
        TimeCardView(viewModel = vm)
    }
}

@Preview(showBackground = true)
@Composable
private fun LoadingViewPreview() {
    TimeCardClientAndroidTheme {
        LoadingView()
    }
}
