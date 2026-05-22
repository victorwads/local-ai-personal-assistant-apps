package com.example.data

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.util.concurrent.atomic.AtomicBoolean

class FirebaseAssistantRepository(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) {
    private val started = AtomicBoolean(false)
    private var memoriesRegistration: ListenerRegistration? = null
    private var subjectsRegistration: ListenerRegistration? = null
    private var nicknamesRegistration: ListenerRegistration? = null
    private var voiceEventsRegistration: ListenerRegistration? = null

    private val _memories = MutableStateFlow<List<FirebaseMemoryItem>>(emptyList())
    val memories: StateFlow<List<FirebaseMemoryItem>> = _memories

    private val _subjects = MutableStateFlow<List<FirebaseSubjectItem>>(emptyList())
    val subjects: StateFlow<List<FirebaseSubjectItem>> = _subjects

    private val _nicknames = MutableStateFlow<List<FirebaseNicknameItem>>(emptyList())
    val nicknames: StateFlow<List<FirebaseNicknameItem>> = _nicknames

    private val _voiceEvents = MutableStateFlow<List<FirebaseVoiceEventItem>>(emptyList())
    val voiceEvents: StateFlow<List<FirebaseVoiceEventItem>> = _voiceEvents

    fun start(profileId: String) {
        if (started.getAndSet(true)) return

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

    fun stop() {
        memoriesRegistration?.remove()
        subjectsRegistration?.remove()
        nicknamesRegistration?.remove()
        voiceEventsRegistration?.remove()
        memoriesRegistration = null
        subjectsRegistration = null
        nicknamesRegistration = null
        voiceEventsRegistration = null
        started.set(false)
    }
}
