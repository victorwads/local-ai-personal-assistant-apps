package com.example.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Hearing
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicNone
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.launch

@Composable
fun VoiceScreen(viewModel: MainViewModel) {
    val isListening by viewModel.isVoiceListening.collectAsStateWithLifecycle()
    val lastTranscript by viewModel.lastVoiceTranscript.collectAsStateWithLifecycle()
    val assistantReply by viewModel.assistantResponseText.collectAsStateWithLifecycle()
    val voiceEvents by viewModel.firebaseVoiceEvents.collectAsStateWithLifecycle()

    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val infiniteTransition = rememberInfiniteTransition(label = "Voice pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 0.94f,
        targetValue = 1.12f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = LinearOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )

    val recorderPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            android.util.Log.d("VoiceScreen", "RECORD_AUDIO granted.")
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text("Voice", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = UiTokens.TextDark)
        Text(
            text = "STT and TTS stay local. Firestore keeps the voice history and pending asks visible.",
            fontSize = 12.sp,
            color = UiTokens.MutedSlate
        )

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(220.dp),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(210.dp)
                    .scale(if (isListening) pulseScale else 1f)
                    .border(1.dp, Color(0xFFDBEAFE), androidx.compose.foundation.shape.CircleShape)
            )
            Box(
                modifier = Modifier
                    .size(150.dp)
                    .scale(if (isListening) pulseScale.coerceAtLeast(0.95f) else 1f)
                    .border(1.dp, Color(0xFFBFDBFE), androidx.compose.foundation.shape.CircleShape)
            )
            Box(
                modifier = Modifier
                    .size(118.dp)
                    .clip(androidx.compose.foundation.shape.CircleShape)
                    .background(Color.White)
                    .border(4.dp, Color(0xFFFDF8F6), androidx.compose.foundation.shape.CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(54.dp)
                        .clip(androidx.compose.foundation.shape.CircleShape)
                        .background(Brush.linearGradient(listOf(UiTokens.PrimaryEmerald, UiTokens.AccentTeal))),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = if (isListening) Icons.Default.Hearing else Icons.Default.MicNone,
                        contentDescription = "Microphone state",
                        tint = Color.White,
                        modifier = Modifier.size(26.dp)
                    )
                }
            }
        }

        Button(
            onClick = {
                val hasAudioPermission = androidx.core.content.ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.RECORD_AUDIO
                ) == android.content.pm.PackageManager.PERMISSION_GRANTED

                if (!hasAudioPermission) {
                    recorderPermissionLauncher.launch(android.Manifest.permission.RECORD_AUDIO)
                    return@Button
                }

                coroutineScope.launch {
                    startSpeechRecognition(context, viewModel)
                }
            },
            colors = ButtonDefaults.buttonColors(containerColor = UiTokens.PrimaryEmerald),
            shape = androidx.compose.foundation.shape.RoundedCornerShape(18.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(
                imageVector = if (isListening) Icons.Default.Hearing else Icons.Default.Mic,
                contentDescription = null,
                tint = Color.White
            )
            Spacer(modifier = Modifier.size(8.dp))
            Text(
                text = if (isListening) "Listening..." else "Tap to Speak",
                color = Color.White,
                fontWeight = FontWeight.Bold
            )
        }

        Card(
            colors = CardDefaults.cardColors(containerColor = UiTokens.CardOverlayBg),
            border = UiTokens.borderStroke(),
            shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("Transcript", fontWeight = FontWeight.Bold, color = UiTokens.TextDark)
                Text(
                    text = lastTranscript.ifBlank { "Your transcript will appear here." },
                    color = if (lastTranscript.isBlank()) UiTokens.MutedSlate else UiTokens.TextDark,
                    fontSize = 13.sp
                )
                Text("Assistant reply", fontWeight = FontWeight.Bold, color = UiTokens.TextDark)
                Text(
                    text = assistantReply,
                    color = UiTokens.TextDark,
                    fontSize = 13.sp
                )
            }
        }

        Text("Voice events", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = UiTokens.TextDark)
        if (voiceEvents.isEmpty()) {
            Text("No voice events found in Firestore yet.", color = UiTokens.MutedSlate)
        } else {
            androidx.compose.foundation.lazy.LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                items(voiceEvents) { event ->
                    VoiceEventCard(event)
                }
            }
        }
    }
}
