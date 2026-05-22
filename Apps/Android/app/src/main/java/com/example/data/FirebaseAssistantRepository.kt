package com.example.data

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.Timestamp
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.util.Date
import java.util.concurrent.atomic.AtomicBoolean
import java.util.UUID

class FirebaseAssistantRepository(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) {
    private val started = AtomicBoolean(false)
    private var profilesRegistration: ListenerRegistration? = null
    private var memoriesRegistration: ListenerRegistration? = null
    private var subjectsRegistration: ListenerRegistration? = null
    private var nicknamesRegistration: ListenerRegistration? = null
    private var voiceEventsRegistration: ListenerRegistration? = null
    private var currentProfileId: String? = null

    private val _profiles = MutableStateFlow<List<FirebaseProfileItem>>(emptyList())
    val profiles: StateFlow<List<FirebaseProfileItem>> = _profiles

    private val _memories = MutableStateFlow<List<FirebaseMemoryItem>>(emptyList())
    val memories: StateFlow<List<FirebaseMemoryItem>> = _memories

    private val _subjects = MutableStateFlow<List<FirebaseSubjectItem>>(emptyList())
    val subjects: StateFlow<List<FirebaseSubjectItem>> = _subjects

    private val _nicknames = MutableStateFlow<List<FirebaseNicknameItem>>(emptyList())
    val nicknames: StateFlow<List<FirebaseNicknameItem>> = _nicknames

    private val _voiceEvents = MutableStateFlow<List<FirebaseVoiceEventItem>>(emptyList())
    val voiceEvents: StateFlow<List<FirebaseVoiceEventItem>> = _voiceEvents

    fun start(profileId: String? = null) {
        startProfilesListener()
        if (profileId == null) return
        if (started.get() && currentProfileId == profileId) return
        memoriesRegistration?.remove()
        subjectsRegistration?.remove()
        nicknamesRegistration?.remove()
        voiceEventsRegistration?.remove()
        currentProfileId = profileId
        started.set(true)
        attachProfileListeners(profileId)
    }

    fun stop() {
        profilesRegistration?.remove()
        memoriesRegistration?.remove()
        subjectsRegistration?.remove()
        nicknamesRegistration?.remove()
        voiceEventsRegistration?.remove()
        profilesRegistration = null
        memoriesRegistration = null
        subjectsRegistration = null
        nicknamesRegistration = null
        voiceEventsRegistration = null
        currentProfileId = null
        started.set(false)
    }

    private fun startProfilesListener() {
        if (profilesRegistration != null) return
        profilesRegistration = firestore.collection("Profiles")
            .addSnapshotListener { snapshot, _ ->
                val items = snapshot?.documents.orEmpty()
                    .mapNotNull { doc -> doc.data?.let { FirebaseProfileItem.fromMap(doc.id, it) } }
                    .sortedWith(compareBy<FirebaseProfileItem> { !it.isDefault }.thenBy { it.displayName.lowercase() })
                _profiles.value = items
            }
    }

    private fun attachProfileListeners(profileId: String) {
        memoriesRegistration = firestore.collection("Profiles/$profileId/Memories")
            .addSnapshotListener { snapshot, _ ->
                val items = snapshot?.documents.orEmpty()
                    .mapNotNull { it.data?.let(FirebaseMemoryItem::fromMap) }
                    .sortedByDescending { it.updatedAt }
                _memories.value = items
            }

        subjectsRegistration = firestore.collection("Profiles/$profileId/Issues")
            .addSnapshotListener { snapshot, _ ->
                val items = snapshot?.documents.orEmpty()
                    .mapNotNull { it.data?.let(FirebaseSubjectItem::fromMap) }
                    .sortedWith(compareByDescending<FirebaseSubjectItem> { it.updatedAt }.thenByDescending { it.priority })
                _subjects.value = items
            }

        nicknamesRegistration = firestore.collection("Profiles/$profileId/Nicknames")
            .addSnapshotListener { snapshot, _ ->
                val items = snapshot?.documents.orEmpty()
                    .mapNotNull { it.data?.let(FirebaseNicknameItem::fromMap) }
                    .sortedByDescending { it.createdAt }
                _nicknames.value = items
            }

        voiceEventsRegistration = firestore.collection("Profiles/$profileId/VoiceEvents")
            .orderBy("createdAt", com.google.firebase.firestore.Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, _ ->
                val items = snapshot?.documents.orEmpty()
                    .mapNotNull { it.data?.let(FirebaseVoiceEventItem::fromMap) }
                _voiceEvents.value = items
            }
    }

    suspend fun addMemory(profileId: String, content: String): FirebaseMemoryItem {
        val item = FirebaseMemoryItem(
            id = UUID.randomUUID().toString(),
            key = content.take(64).ifBlank { "memory" },
            content = content,
            createdAt = Date(),
            updatedAt = Date()
        )
        firestore.document("Profiles/$profileId/Memories/${item.id}")
            .set(
                mapOf(
                    "id" to item.id,
                    "key" to item.key,
                    "content" to item.content,
                    "createdAt" to Timestamp(item.createdAt),
                    "updatedAt" to Timestamp(item.updatedAt)
                )
            )
            .await()
        return item
    }

    suspend fun deleteMemory(profileId: String, id: String) {
        firestore.document("Profiles/$profileId/Memories/$id").delete().await()
    }

    suspend fun addSubject(profileId: String, title: String, notes: String, linkedContact: String? = null): FirebaseSubjectItem {
        val now = Date()
        val item = FirebaseSubjectItem(
            id = UUID.randomUUID().toString(),
            title = title,
            summary = notes,
            status = "active",
            priority = 0,
            createdAt = now,
            updatedAt = now
        )
        val payload = mutableMapOf<String, Any>(
            "id" to item.id,
            "title" to item.title,
            "summary" to item.summary,
            "status" to item.status,
            "priority" to item.priority,
            "createdAt" to Timestamp(item.createdAt),
            "updatedAt" to Timestamp(item.updatedAt)
        )
        linkedContact?.let { payload["linkedContactName"] = it }
        firestore.document("Profiles/$profileId/Issues/${item.id}")
            .set(payload)
            .await()
        return item
    }

    suspend fun updateSubjectStatus(profileId: String, id: String, status: String) {
        firestore.document("Profiles/$profileId/Issues/$id")
            .set(
                mapOf(
                    "status" to status,
                    "updatedAt" to Timestamp(Date())
                ),
                com.google.firebase.firestore.SetOptions.merge()
            )
            .await()
    }

    suspend fun queueVoicePrompt(profileId: String, transcript: String) {
        val docId = UUID.randomUUID().toString()
        firestore.document("Profiles/$profileId/PromptQueue/$docId")
            .set(
                mapOf(
                    "id" to docId,
                    "createdAt" to Timestamp(Date()),
                    "text" to transcript
                )
            )
            .await()
    }
}
