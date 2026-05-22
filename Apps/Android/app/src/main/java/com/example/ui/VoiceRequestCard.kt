package com.example.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.FirebaseVoiceEventItem

@Composable
fun VoiceRequestCard(
    request: FirebaseVoiceEventItem,
    accent: Color,
    trailingLabel: String
) {
    Card(
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = BorderStroke(1.dp, accent.copy(alpha = 0.18f)),
        shape = RoundedCornerShape(14.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row {
                Text(
                    text = request.prompt ?: request.text ?: "Voice event",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = UiTokens.TextDark,
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = trailingLabel,
                    fontSize = 10.sp,
                    color = accent,
                    fontWeight = FontWeight.Bold
                )
            }
            Text(
                text = request.transcript ?: request.draftTranscript ?: "No transcript yet",
                fontSize = 12.sp,
                color = UiTokens.MutedSlate,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = request.kind.uppercase(),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                    color = accent
                )
                if (!request.askStatus.isNullOrBlank()) {
                    Text(
                        text = "Status: ${request.askStatus}",
                        fontSize = 10.sp,
                        color = UiTokens.MutedSlate
                    )
                }
                if (request.answeredAt != null) {
                    Text(
                        text = "Answered: ${DateFormatters.shortTime(request.answeredAt)}",
                        fontSize = 10.sp,
                        color = UiTokens.MutedSlate
                    )
                }
            }
        }
    }
}
