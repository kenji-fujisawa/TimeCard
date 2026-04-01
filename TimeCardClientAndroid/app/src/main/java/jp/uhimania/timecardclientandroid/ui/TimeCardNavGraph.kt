package jp.uhimania.timecardclientandroid.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import jp.uhimania.timecardclientandroid.ui.NavigationArgs.DATE_ARG
import jp.uhimania.timecardclientandroid.ui.NavigationRoutes.CALENDAR_DETAIL_ROUTE
import jp.uhimania.timecardclientandroid.ui.NavigationRoutes.CALENDAR_ROUTE
import jp.uhimania.timecardclientandroid.ui.NavigationViews.CALENDAR_DETAIL_SCREEN
import jp.uhimania.timecardclientandroid.ui.NavigationViews.CALENDAR_SCREEN

object NavigationViews {
    const val CALENDAR_SCREEN = "calendar"
    const val CALENDAR_DETAIL_SCREEN = "detail"
}

object NavigationArgs {
    const val DATE_ARG = "date"
}

object NavigationRoutes {
    const val CALENDAR_ROUTE = CALENDAR_SCREEN
    const val CALENDAR_DETAIL_ROUTE = "$CALENDAR_DETAIL_SCREEN/{$DATE_ARG}"
}

@Composable
fun TimeCardNavGraph(
    modifier: Modifier = Modifier,
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = CALENDAR_ROUTE,
        modifier = modifier
    ) {
        composable(CALENDAR_ROUTE) {
            CalendarScreen(
                onDateSelect = { navController.navigate("$CALENDAR_DETAIL_SCREEN/${it.time}") }
            )
        }
        composable(
            route = CALENDAR_DETAIL_ROUTE,
            arguments = listOf(
                navArgument(DATE_ARG) { type = NavType.LongType }
            )
        ) {
            CalendarDetailScreen(
                onBack = {
                    navController.popBackStack()
                }
            )
        }
    }
}
