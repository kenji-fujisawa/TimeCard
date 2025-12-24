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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
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
import jp.uhimania.timecardclientandroid.data.CalendarRecordSaver
import jp.uhimania.timecardclientandroid.data.datesOf
import jp.uhimania.timecardclientandroid.data.day
import jp.uhimania.timecardclientandroid.ui.NavigationArgs.DAY_ARG
import jp.uhimania.timecardclientandroid.ui.NavigationRoutes.CALENDAR_DETAIL_ROUTE
import jp.uhimania.timecardclientandroid.ui.NavigationRoutes.CALENDAR_ROUTE
import jp.uhimania.timecardclientandroid.ui.NavigationViews.CALENDAR_DETAIL_VIEW
import jp.uhimania.timecardclientandroid.ui.NavigationViews.CALENDAR_VIEW
import jp.uhimania.timecardclientandroid.ui.theme.TimeCardClientAndroidTheme
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
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
    TimeCardClientAndroidTheme {
        val vm = CalendarViewModel(FakeCalendarRecordRepository())
        TimeCardView(viewModel = vm)
    }
}

private class FakeCalendarRecordRepository : CalendarRecordRepository {
    override fun getRecords(year: Int, month: Int): Flow<List<CalendarRecord>> {
        val records = Calendar.getInstance().datesOf(year, month).map {
            CalendarRecord(it, listOf())
        }
        return flowOf(records)
    }

    override suspend fun updateRecord(source: List<CalendarRecord>, record: CalendarRecord) {}
}

@Preview(showBackground = true)
@Composable
private fun LoadingViewPreview() {
    TimeCardClientAndroidTheme {
        LoadingView()
    }
}
