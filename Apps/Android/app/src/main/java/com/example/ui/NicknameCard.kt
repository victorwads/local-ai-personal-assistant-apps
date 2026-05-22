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
import com.example.data.FirebaseNicknameItem

@Composable
fun NicknameCard(item: FirebaseNicknameItem) {
    Card(
        colors = CardDefaults.cardColors(containerColor = UiTokens.CardOverlayBg),
        border = BorderStroke(1.dp, UiTokens.BorderColor),
        shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row {
                Text(
                    text = item.nickname,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = UiTokens.TextDark,
                    modifier = Modifier.weight(1f)
                )
                Text(DateFormatters.shortDateTime(item.createdAt), color = UiTokens.MutedSlate, fontSize = 11.sp)
            }
            Text("Original: ${item.originalName}", color = UiTokens.MutedSlate, fontSize = 13.sp)
            if (!item.chatId.isNullOrBlank()) {
                Text("Chat ID: ${item.chatId}", color = UiTokens.MutedSlate, fontSize = 11.sp)
            }
        }
    }
}
