package com.example.data

data class VoicePromptResponse(
    val replyText: String,
    val speakText: String,
    val updatedSubjects: List<SubjectItem> = emptyList(),
    val addedMemories: List<MemoryItem> = emptyList()
)
