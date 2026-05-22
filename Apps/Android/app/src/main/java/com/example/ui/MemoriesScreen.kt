package com.example.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SearchOff
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun MemoriesScreen(viewModel: MainViewModel) {
    val memories by viewModel.firebaseMemories.collectAsStateWithLifecycle()
    var searchQuery by remember { mutableStateOf("") }

    val filtered = memories.filter {
        it.key.contains(searchQuery, ignoreCase = true) || it.content.contains(searchQuery, ignoreCase = true)
    }

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Text("Memories", fontSize = 22.sp, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold, color = UiTokens.TextDark)
        Spacer(modifier = Modifier.height(8.dp))
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { searchQuery = it },
            placeholder = { Text("Search memories...", color = UiTokens.MutedSlate) },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = "Search", tint = UiTokens.MutedSlate) },
            singleLine = true,
            shape = androidx.compose.foundation.shape.RoundedCornerShape(24.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = UiTokens.PrimaryEmerald,
                unfocusedBorderColor = UiTokens.BorderColor,
                focusedTextColor = UiTokens.TextDark,
                unfocusedTextColor = UiTokens.TextDark,
                focusedContainerColor = UiTokens.CardOverlayBg,
                unfocusedContainerColor = UiTokens.CardOverlayBg
            ),
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(16.dp))

        if (filtered.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.SearchOff, contentDescription = null, tint = UiTokens.MutedSlate)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = if (searchQuery.isBlank()) "No memories found in Firestore yet." else "No memory matches your search.",
                        color = UiTokens.MutedSlate
                    )
                }
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                items(filtered) { memory ->
                    MemoryCard(memory = memory)
                }
            }
        }
    }
}
