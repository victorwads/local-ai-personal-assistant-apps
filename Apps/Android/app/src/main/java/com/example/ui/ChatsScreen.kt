package com.example.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.ChatItem
import java.util.Locale

@Composable
fun ChatsScreen(viewModel: MainViewModel) {
    val chats by viewModel.chats.collectAsStateWithLifecycle()
    val activeChatId by viewModel.activeChatId.collectAsStateWithLifecycle()
    val activeChatMessages by viewModel.activeChatMessages.collectAsStateWithLifecycle()

    var textInput by remember { mutableStateOf("") }

    if (activeChatId != null) {
        // Detailed conversation window
        val chatObj = chats.find { it.id == activeChatId }
        Column(modifier = Modifier.fillMaxSize()) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFFEFF6FF))
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = { viewModel.selectChat("") }) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back to inbox", tint = UiTokens.TextDark)
                }
                Spacer(modifier = Modifier.width(8.dp))
                Column {
                    Text(chatObj?.name ?: "WhatsApp Contact", color = UiTokens.TextDark, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    Text("WhatsApp Web Polling", color = UiTokens.WaveformGreen, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                }
            }

            // Message list
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .background(UiTokens.MidnightBg)
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                reverseLayout = false,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(activeChatMessages) { (text, isMe) ->
                    val bubbleBg = if (isMe) Color(0xFFEDF5F1) else Color(0xFFFFFFFF)
                    val align = if (isMe) Alignment.End else Alignment.Start

                    Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = align) {
                        Box(
                            modifier = Modifier
                                .clip(
                                    RoundedCornerShape(
                                        topStart = 12.dp,
                                        topEnd = 12.dp,
                                        bottomStart = if (isMe) 12.dp else 0.dp,
                                        bottomEnd = if (isMe) 0.dp else 12.dp
                                    )
                                )
                                .background(bubbleBg)
                                .border(width = 0.5.dp, color = UiTokens.BorderColor, shape = RoundedCornerShape(
                                    topStart = 12.dp,
                                    topEnd = 12.dp,
                                    bottomStart = if (isMe) 12.dp else 0.dp,
                                    bottomEnd = if (isMe) 0.dp else 12.dp
                                ))
                                .padding(12.dp)
                        ) {
                            Text(text, color = UiTokens.TextDark, fontSize = 14.sp)
                        }
                    }
                }
            }

            // Typing area
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFFEFF6FF))
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = textInput,
                    onValueChange = { textInput = it },
                    placeholder = { Text("Type remote message here...", color = UiTokens.MutedSlate) },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = UiTokens.PrimaryEmerald,
                        unfocusedBorderColor = UiTokens.BorderColor,
                        focusedTextColor = UiTokens.TextDark,
                        unfocusedTextColor = UiTokens.TextDark,
                        focusedContainerColor = Color.White,
                        unfocusedContainerColor = Color.White
                    ),
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                IconButton(onClick = {
                    if (textInput.isNotBlank()) {
                        viewModel.sendChatMessage(activeChatId!!, textInput)
                        textInput = ""
                    }
                }) {
                    Icon(Icons.Default.Send, contentDescription = "Send", tint = UiTokens.PrimaryEmerald, modifier = Modifier.size(28.dp))
                }
            }
        }
    } else {
        // Chat Inbox list
        Column(modifier = Modifier.padding(16.dp)) {
            Text("WhatsApp Active Feeds", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = UiTokens.TextDark)
            Spacer(modifier = Modifier.height(4.dp))
            Text("Observing local Mac accessibility tree. Select a conversation below to manage chats from this client.", fontSize = 12.sp, color = UiTokens.MutedSlate)
            Spacer(modifier = Modifier.height(16.dp))

            if (chats.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("No chats active. Re-verify accessibility permissions on macOS.", color = UiTokens.MutedSlate)
                }
            } else {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(chats) { chat ->
                        ChatItemRow(chat, onClick = { viewModel.selectChat(chat.id) })
                    }
                }
            }
        }
    }
}
