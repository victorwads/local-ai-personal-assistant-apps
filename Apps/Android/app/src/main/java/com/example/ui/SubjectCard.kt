package com.example.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.FirebaseSubjectItem

@Composable
fun SubjectCard(subject: FirebaseSubjectItem) {
    val statusColor = when (subject.status.lowercase()) {
        "active" -> Color(0xFFD97706)
        "resolved" -> UiTokens.WaveformGreen
        "canceled", "cancelled" -> Color(0xFFB42318)
        else -> UiTokens.MutedSlate
    }

    Card(
        colors = CardDefaults.cardColors(containerColor = UiTokens.CardOverlayBg),
        border = BorderStroke(1.dp, UiTokens.BorderColor),
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row {
                Text(
                    text = subject.title,
                    fontWeight = FontWeight.Bold,
                    color = UiTokens.TextDark,
                    fontSize = 15.sp,
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                androidx.compose.foundation.layout.Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(999.dp))
                        .background(statusColor.copy(alpha = 0.12f))
                        .border(1.dp, statusColor.copy(alpha = 0.25f), RoundedCornerShape(999.dp))
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(subject.status, color = statusColor, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                }
            }
            Text(subject.summary.ifBlank { "No summary available." }, color = UiTokens.MutedSlate, fontSize = 13.sp)
            Row(modifier = Modifier.fillMaxWidth()) {
                Text("Priority ${subject.priority}", color = UiTokens.MutedSlate, fontSize = 11.sp)
                Spacer(modifier = Modifier.weight(1f))
                Text(DateFormatters.shortDateTime(subject.updatedAt), color = UiTokens.MutedSlate, fontSize = 11.sp)
            }
        }
    }
}
