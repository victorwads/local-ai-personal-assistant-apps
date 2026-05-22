package com.example.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.FirebaseVoiceEventItem

@Composable
fun VoiceEventCard(event: FirebaseVoiceEventItem) {
    val accent = when (event.kind.lowercase()) {
        "ask" -> UiTokens.PrimaryEmerald
        "speak" -> UiTokens.AccentTeal
        else -> UiTokens.MutedSlate
    }
    Card(
        colors = CardDefaults.cardColors(containerColor = UiTokens.CardOverlayBg),
        border = BorderStroke(1.dp, accent.copy(alpha = 0.18f)),
        shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row {
                Text(
                    text = event.kind.uppercase(),
                    fontWeight = FontWeight.Bold,
                    color = accent,
                    fontSize = 11.sp
                )
                Spacer(modifier = Modifier.weight(1f))
                Text(DateFormatters.shortTime(event.createdAt), color = UiTokens.MutedSlate, fontSize = 11.sp)
            }
            if (!event.prompt.isNullOrBlank()) {
                Text(event.prompt!!, color = UiTokens.TextDark, fontSize = 13.sp)
            }
            if (!event.text.isNullOrBlank()) {
                Text(event.text!!, color = UiTokens.MutedSlate, fontSize = 12.sp)
            }
            if (!event.transcript.isNullOrBlank()) {
                Text("Response: ${event.transcript}", color = UiTokens.MutedSlate, fontSize = 12.sp)
            }
            if (!event.askStatus.isNullOrBlank()) {
                Text("Status: ${event.askStatus}", color = UiTokens.MutedSlate, fontSize = 11.sp)
            }
        }
    }
}
