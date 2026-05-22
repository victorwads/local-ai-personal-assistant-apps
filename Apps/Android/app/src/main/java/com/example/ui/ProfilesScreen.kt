package com.example.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Router
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun ProfilesScreen(viewModel: MainViewModel) {
    val profiles by viewModel.profiles.collectAsStateWithLifecycle()
    val activeProfile by viewModel.activeProfile.collectAsStateWithLifecycle()

    var showAddDialog by remember { mutableStateOf(false) }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Connection Profiles", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = UiTokens.TextDark)
                IconButton(onClick = { showAddDialog = true }) {
                    Icon(Icons.Default.AddCircle, contentDescription = "Add Profile", tint = UiTokens.PrimaryEmerald, modifier = Modifier.size(28.dp))
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text("Create multiple Profiles for remote access. Connect to your house, office, or client sites.", fontSize = 12.sp, color = UiTokens.MutedSlate)
            Spacer(modifier = Modifier.height(16.dp))

            if (profiles.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(Icons.Default.Router, contentDescription = "Router", tint = UiTokens.MutedSlate, modifier = Modifier.size(48.dp))
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("No Profiles saved. Create one using the plus button above!", color = UiTokens.MutedSlate, textAlign = TextAlign.Center)
                    }
                }
            } else {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    items(profiles) { profile ->
                        val isActive = activeProfile?.id == profile.id
                        ProfileRowCard(
                            profile,
                            isActive,
                            onSelect = { viewModel.selectProfile(profile.id) },
                            onDelete = { viewModel.deleteProfile(profile) }
                        )
                    }
                }
            }
        }

        if (showAddDialog) {
            AddProfileDialog(
                onDismiss = { showAddDialog = false },
                onAdd = { name, host, port, apiKey ->
                    viewModel.addProfile(name, host, port, apiKey)
                    showAddDialog = false
                }
            )
        }
    }
}
