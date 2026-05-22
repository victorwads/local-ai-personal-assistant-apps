package com.example.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.FirebaseMemoryItem

@Composable
fun MemoryCard(memory: FirebaseMemoryItem) {
    Card(
        colors = CardDefaults.cardColors(containerColor = UiTokens.CardOverlayBg),
        border = BorderStroke(1.dp, UiTokens.BorderColor),
        shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row {
                Text(
                    text = memory.key,
                    fontWeight = FontWeight.Bold,
                    color = UiTokens.TextDark,
                    fontSize = 15.sp,
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = DateFormatters.shortDateTime(memory.updatedAt),
                    fontSize = 11.sp,
                    color = UiTokens.MutedSlate
                )
            }
            Text(
                text = memory.content,
                color = UiTokens.MutedSlate,
                fontSize = 13.sp
            )
        }
    }
}
