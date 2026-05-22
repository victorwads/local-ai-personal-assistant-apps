package com.example.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Tag
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun NicknamesScreen(viewModel: MainViewModel) {
    val nicknames by viewModel.firebaseNicknames.collectAsStateWithLifecycle()

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Text("Nicknames", fontSize = 22.sp, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold, color = UiTokens.TextDark)
        Spacer(modifier = Modifier.height(8.dp))

        if (nicknames.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.Tag, contentDescription = null, tint = UiTokens.MutedSlate)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("No nicknames found in Firestore yet.", color = UiTokens.MutedSlate)
                }
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                items(nicknames) { nickname ->
                    NicknameCard(nickname)
                }
            }
        }
    }
}
