package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class VoicePromptResponse(
    val replyText: String,
    val speakText: String,
    val updatedSubjects: List<SubjectItem> = emptyList(),
    val addedMemories: List<MemoryItem> = emptyList()
)
