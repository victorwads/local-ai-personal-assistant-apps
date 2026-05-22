package com.example.data

import retrofit2.http.*

interface ApiService {
    @GET("api/remote/status")
    suspend fun getStatus(
        @Header("Authorization") token: String? = null
    ): ServerStatus

    @GET("api/remote/memories")
    suspend fun getMemories(
        @Header("Authorization") token: String? = null
    ): List<MemoryItem>

    @POST("api/remote/memories")
    suspend fun createMemory(
        @Body request: CreateMemoryRequest,
        @Header("Authorization") token: String? = null
    ): MemoryItem

    @DELETE("api/remote/memories/{id}")
    suspend fun deleteMemory(
        @Path("id") id: String,
        @Header("Authorization") token: String? = null
    )

    @GET("api/remote/subjects")
    suspend fun getSubjects(
        @Header("Authorization") token: String? = null
    ): List<SubjectItem>

    @POST("api/remote/subjects")
    suspend fun createSubject(
        @Body request: CreateSubjectRequest,
        @Header("Authorization") token: String? = null
    ): SubjectItem

    @PUT("api/remote/subjects/{id}")
    suspend fun updateSubject(
        @Path("id") id: String,
        @Body request: UpdateSubjectRequest,
        @Header("Authorization") token: String? = null
    ): SubjectItem

    @DELETE("api/remote/subjects/{id}")
    suspend fun deleteSubject(
        @Path("id") id: String,
        @Header("Authorization") token: String? = null
    )

    @GET("api/remote/chats")
    suspend fun getChats(
        @Header("Authorization") token: String? = null
    ): List<ChatItem>

    @POST("api/remote/chats/{chatId}/send")
    suspend fun sendMessage(
        @Path("chatId") chatId: String,
        @Body request: SendMessageRequest,
        @Header("Authorization") token: String? = null
    ): ChatItem

    @POST("api/remote/voice/prompt")
    suspend fun submitVoicePrompt(
        @Body request: VoicePromptRequest,
        @Header("Authorization") token: String? = null
    ): VoicePromptResponse

    @GET("api/remote/voice/push-messages")
    suspend fun getPendingPushMessages(
        @Header("Authorization") token: String? = null
    ): PendingPushMessagesResponse
}
