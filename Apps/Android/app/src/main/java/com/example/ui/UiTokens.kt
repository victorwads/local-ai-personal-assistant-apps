package com.example.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

object UiTokens {
    val MidnightBg = Color(0xFFFDF8F6)
    val CardOverlayBg = Color(0xFFFFFFFF)
    val WaveformGreen = Color(0xFF059669)
    val PrimaryEmerald = Color(0xFF2563EB)
    val AccentTeal = Color(0xFF4F46E5)
    val BorderColor = Color(0xFFF1F5F9)
    val MutedSlate = Color(0xFF64748B)
    val TextDark = Color(0xFF1E293B)

    fun borderStroke() = BorderStroke(1.dp, BorderColor)
}
