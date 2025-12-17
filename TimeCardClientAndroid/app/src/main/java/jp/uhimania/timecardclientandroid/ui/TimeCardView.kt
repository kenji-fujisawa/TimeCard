package jp.uhimania.timecardclientandroid.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
import jp.uhimania.timecardclientandroid.data.CalendarRecordSaver
import jp.uhimania.timecardclientandroid.data.datesOf
import jp.uhimania.timecardclientandroid.data.day
import jp.uhimania.timecardclientandroid.ui.NavigationArgs.DAY_ARG
import jp.uhimania.timecardclientandroid.ui.NavigationRoutes.CALENDAR_DETAIL_ROUTE
import jp.uhimania.timecardclientandroid.ui.NavigationRoutes.CALENDAR_ROUTE
import jp.uhimania.timecardclientandroid.ui.NavigationViews.CALENDAR_DETAIL_VIEW
import jp.uhimania.timecardclientandroid.ui.NavigationViews.CALENDAR_VIEW
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import java.util.Calendar

private object NavigationViews {
    const val CALENDAR_VIEW = "calendar"
    const val CALENDAR_DETAIL_VIEW = "detail"
}

private object NavigationArgs {
    const val DAY_ARG = "day"
}

private object NavigationRoutes {
    const val CALENDAR_ROUTE = CALENDAR_VIEW
    const val CALENDAR_DETAIL_ROUTE = "$CALENDAR_DETAIL_VIEW/{$DAY_ARG}"
}

@Composable
fun TimeCardView(
    modifier: Modifier = Modifier,
    navController: NavHostController = rememberNavController(),
    viewModel: CalendarViewModel = viewModel(factory = CalendarViewModel.Factory)
) {
    val uiState by viewModel.uiState.collectAsState()
    if (uiState.isLoading) {
        LoadingView()
    } else {
        NavHost(
            navController = navController,
            startDestination = CALENDAR_ROUTE,
            modifier = modifier
        ) {
            composable(CALENDAR_ROUTE) {
                CalendarView(
                    date = uiState.date,
                    records = uiState.records,
                    onDateChange = { viewModel.updateDate(it) },
                    onDateSelect = { navController.navigate("$CALENDAR_DETAIL_VIEW/${it.date.day()}") }
                )
            }
            composable(
                route = CALENDAR_DETAIL_ROUTE,
                arguments = listOf(
                    navArgument(DAY_ARG) { type = NavType.IntType }
                )
            ) { entry ->
                val day = entry.arguments?.getInt(DAY_ARG)
                val rec = uiState.records.first { it.date.day() == day }
                var record by rememberSaveable(stateSaver = CalendarRecordSaver) {
                    mutableStateOf(rec)
                }
                CalendarDetailView(
                    record = record,
                    onRecordChange = { record = it },
                    onBack = {
                        navController.popBackStack()
                        viewModel.updateRecord(record)
                    }
                )
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

@Preview(showBackground = true)
@Composable
private fun TimeCardViewPreview() {
    TimeCardClientAndroidTheme {
        val vm = CalendarViewModel(FakeCalendarRecordRepository())
        TimeCardView(viewModel = vm)
    }
}

private class FakeCalendarRecordRepository : CalendarRecordRepository {
    override suspend fun getRecords(year: Int, month: Int): List<CalendarRecord> {
        return Calendar.getInstance().datesOf(year, month).map {
            CalendarRecord(it, listOf())
        }
    }

    override suspend fun updateRecord(source: List<CalendarRecord>, record: CalendarRecord): List<CalendarRecord> {
        return source
    }
}

@Preview(showBackground = true)
@Composable
private fun LoadingViewPreview() {
    TimeCardClientAndroidTheme {
        LoadingView()
    }
}
