package com.example.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppNavigation(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val activeScreen = remember { mutableStateOf<Screen>(Screen.Home) }

    val status by viewModel.status.collectAsStateWithLifecycle()
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "Assistant Voice Remote",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            color = UiTokens.TextDark
                        )
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            val activeDotColor = if (status?.connected == true) UiTokens.WaveformGreen else Color(0xFFFFB300)
                            val statusLabel = if (status?.connected == true) "Connected Mac" else "Waiting for Firestore"
                            
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .background(activeDotColor, CircleShape)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = statusLabel,
                                fontSize = 11.sp,
                                color = UiTokens.MutedSlate
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = UiTokens.MidnightBg,
                    titleContentColor = UiTokens.TextDark
                )
            )
        },
        bottomBar = {
            NavigationBar(
                containerColor = Color.White,
                tonalElevation = 8.dp,
                modifier = Modifier.border(width = (0.5).dp, color = UiTokens.BorderColor, shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
            ) {
                listOf(Screen.Home, Screen.Memories, Screen.Subjects, Screen.Nicknames, Screen.Voice).forEach { screen ->
                    val selected = activeScreen.value == screen
                    NavigationBarItem(
                        selected = selected,
                        onClick = { activeScreen.value = screen },
                        label = { Text(screen.title, fontSize = 11.sp, fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal) },
                        icon = {
                            Icon(
                                imageVector = screen.icon,
                                contentDescription = screen.title,
                                tint = if (selected) UiTokens.PrimaryEmerald else UiTokens.MutedSlate
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = UiTokens.PrimaryEmerald,
                            unselectedIconColor = UiTokens.MutedSlate,
                            selectedTextColor = UiTokens.PrimaryEmerald,
                            unselectedTextColor = UiTokens.MutedSlate,
                            indicatorColor = Color(0xFFEFF6FF)
                        )
                    )
                }
            }
        },
        containerColor = UiTokens.MidnightBg
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .padding(paddingValues)
                .fillMaxSize()
        ) {
            when (activeScreen.value) {
                Screen.Home -> DashboardScreen(viewModel)
                Screen.Memories -> MemoriesScreen(viewModel)
                Screen.Subjects -> SubjectsScreen(viewModel)
                Screen.Nicknames -> NicknamesScreen(viewModel)
                Screen.Voice -> VoiceScreen(viewModel)
            }
        }
    }
}
