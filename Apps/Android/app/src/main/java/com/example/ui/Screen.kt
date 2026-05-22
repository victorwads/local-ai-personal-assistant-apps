package com.example.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Tag
import androidx.compose.material.icons.filled.Task
import androidx.compose.ui.graphics.vector.ImageVector

sealed class Screen(val route: String, val title: String, val icon: ImageVector) {
    object Home : Screen("home", "Home", Icons.Default.Dashboard)
    object Memories : Screen("memories", "Memories", Icons.Default.Psychology)
    object Subjects : Screen("subjects", "Subjects", Icons.Default.Task)
    object Nicknames : Screen("nicknames", "Nicknames", Icons.Default.Tag)
    object Voice : Screen("voice", "Voice", Icons.Default.Mic)
}
