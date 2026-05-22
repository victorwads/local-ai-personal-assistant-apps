package com.example.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.FirebaseProfileItem
import com.google.firebase.auth.FirebaseUser

@Composable
fun ProfileSelectionScreen(
    firebaseUser: FirebaseUser?,
    profiles: List<FirebaseProfileItem>,
    selectedProfileId: String?,
    onProfileSelected: (String) -> Unit,
    onConfirmSelection: () -> Unit
) {
    val clipboardManager = LocalClipboardManager.current
    var copiedUid by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    listOf(Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFF5F3FF))
                )
            )
            .padding(20.dp),
        contentAlignment = Alignment.Center
    ) {
        Card(
            colors = CardDefaults.cardColors(containerColor = Color.White),
            border = UiTokens.borderStroke(),
            shape = RoundedCornerShape(24.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(52.dp)
                            .clip(CircleShape)
                            .background(Brush.linearGradient(listOf(UiTokens.PrimaryEmerald, UiTokens.AccentTeal))),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Lock,
                            contentDescription = "Temporary profile picker",
                            tint = Color.White,
                            modifier = Modifier.size(24.dp)
                        )
                    }

                    Spacer(modifier = Modifier.size(12.dp))

                    Column {
                        Text(
                            text = "Temporary profile selection",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = UiTokens.TextDark
                        )
                        Text(
                            text = "This screen is a temporary bridge until Firebase UID to profile mapping is handled on the server.",
                            fontSize = 13.sp,
                            color = UiTokens.MutedSlate
                        )
                    }
                }

                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "Signed in with",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = UiTokens.MutedSlate
                    )
                    Text(
                        text = firebaseUser?.email ?: "Google account",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = UiTokens.TextDark
                    )
                    Text(
                        text = "Firebase UID",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = UiTokens.MutedSlate
                    )
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .background(UiTokens.MidnightBg)
                            .border(1.dp, UiTokens.BorderColor, RoundedCornerShape(14.dp))
                            .padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = firebaseUser?.uid ?: "Unavailable",
                            fontSize = 12.sp,
                            color = UiTokens.TextDark,
                            modifier = Modifier.weight(1f)
                        )
                        OutlinedButton(onClick = {
                            firebaseUser?.uid?.let {
                                clipboardManager.setText(AnnotatedString(it))
                                copiedUid = true
                            }
                        }) {
                            Icon(
                                imageVector = Icons.Default.ContentCopy,
                                contentDescription = "Copy Firebase UID",
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.size(6.dp))
                            Text(if (copiedUid) "Copied" else "Copy")
                        }
                    }
                }

                if (profiles.isEmpty()) {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = Color(0xFFF8FAFC)),
                        border = UiTokens.borderStroke(),
                        shape = RoundedCornerShape(16.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                text = "No profiles available yet",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = UiTokens.TextDark
                            )
                            Text(
                                text = "The final flow will block here until the server associates this Firebase account with a profile. For now, there is nothing to select on this device.",
                                fontSize = 13.sp,
                                color = UiTokens.MutedSlate
                            )
                        }
                    }
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(
                            text = "Choose the profile for this session",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = UiTokens.TextDark
                        )
                        LazyColumn(
                            modifier = Modifier.heightIn(max = 320.dp),
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            items(profiles) { profile ->
                                val isSelected = selectedProfileId == profile.id
                                val isCurrentActive = profile.isDefault
                                ProfileSelectionCard(
                                    profile = profile,
                                    isSelected = isSelected,
                                    isCurrentActive = isCurrentActive,
                                    onClick = { onProfileSelected(profile.id) }
                                )
                            }
                        }
                    }
                }

                Button(
                    onClick = onConfirmSelection,
                    enabled = selectedProfileId != null && profiles.isNotEmpty(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = UiTokens.PrimaryEmerald,
                        contentColor = Color.White
                    ),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Continue with selected profile")
                }
            }
        }
    }
}

@Composable
private fun ProfileSelectionCard(
    profile: FirebaseProfileItem,
    isSelected: Boolean,
    isCurrentActive: Boolean,
    onClick: () -> Unit
) {
    val borderColor = when {
        isSelected -> UiTokens.PrimaryEmerald
        isCurrentActive -> UiTokens.AccentTeal
        else -> UiTokens.BorderColor
    }
    val backgroundColor = when {
        isSelected -> Color(0xFFEFF6FF)
        isCurrentActive -> Color(0xFFF8FAFC)
        else -> UiTokens.CardOverlayBg
    }

    Card(
        colors = CardDefaults.cardColors(containerColor = backgroundColor),
        border = androidx.compose.foundation.BorderStroke(1.dp, borderColor),
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.AccountCircle,
                        contentDescription = "Profile",
                        tint = if (isSelected) UiTokens.PrimaryEmerald else UiTokens.MutedSlate
                    )
                    Spacer(modifier = Modifier.size(8.dp))
                    Text(
                        text = profile.displayName,
                        fontWeight = FontWeight.Bold,
                        color = UiTokens.TextDark,
                        fontSize = 15.sp
                    )
                }

                if (isSelected) {
                    Box(
                        modifier = Modifier
                            .background(UiTokens.PrimaryEmerald.copy(alpha = 0.2f), RoundedCornerShape(6.dp))
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = "SELECTED",
                            color = UiTokens.PrimaryEmerald,
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                } else if (isCurrentActive) {
                    Box(
                        modifier = Modifier
                            .background(UiTokens.AccentTeal.copy(alpha = 0.15f), RoundedCornerShape(6.dp))
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = "ACTIVE",
                            color = UiTokens.AccentTeal,
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            Text(
                text = "Profile ID: ${profile.id}",
                color = UiTokens.MutedSlate,
                fontSize = 12.sp
            )
            Text(
                text = if (profile.isAutoStart) "Auto-start enabled on the server." else "Manual selection on the server.",
                color = UiTokens.AccentTeal,
                fontSize = 11.sp
            )
            Text(
                text = if (isSelected) "Tap continue to enter the app with this profile." else "Tap to select this profile for the current session.",
                color = UiTokens.MutedSlate,
                fontSize = 11.sp,
                textAlign = TextAlign.Start
            )
        }
    }
}
