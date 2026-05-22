package com.example.ui

import android.app.Application
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.io.File
import java.util.Locale
import java.util.UUID

class MainViewModel(application: Application) : AndroidViewModel(application), TextToSpeech.OnInitListener {
    private val db = AppDatabase.getDatabase(application)
    private val repository = ProfileRepository(db.selectedProfileDao())
    private val firebaseRepository = FirebaseAssistantRepository()

    // Live state streams
    val firebaseProfiles = firebaseRepository.profiles.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )

    val selectedProfileState = repository.selectedProfile.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = null
    )

    val selectedProfile = combine(firebaseProfiles, selectedProfileState) { profiles, selectedState ->
        val selectedId = selectedState?.selectedProfileId
        if (selectedId == null) null else profiles.firstOrNull { it.id == selectedId }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = null
    )

    private val _status = MutableStateFlow<ServerStatus?>(null)
    val status: StateFlow<ServerStatus?> = _status.asStateFlow()

    private val _memories = MutableStateFlow<List<MemoryItem>>(emptyList())
    val memories: StateFlow<List<MemoryItem>> = _memories.asStateFlow()

    private val _subjects = MutableStateFlow<List<SubjectItem>>(emptyList())
    val subjects: StateFlow<List<SubjectItem>> = _subjects.asStateFlow()

    private val _voiceRequests = MutableStateFlow<List<VoiceRequestItem>>(emptyList())
    val voiceRequests: StateFlow<List<VoiceRequestItem>> = _voiceRequests.asStateFlow()

    val firebaseMemories: StateFlow<List<FirebaseMemoryItem>> = firebaseRepository.memories
    val firebaseSubjects: StateFlow<List<FirebaseSubjectItem>> = firebaseRepository.subjects
    val firebaseNicknames: StateFlow<List<FirebaseNicknameItem>> = firebaseRepository.nicknames
    val firebaseVoiceEvents: StateFlow<List<FirebaseVoiceEventItem>> = firebaseRepository.voiceEvents

    private val _chats = MutableStateFlow<List<ChatItem>>(emptyList())
    val chats: StateFlow<List<ChatItem>> = _chats.asStateFlow()

    private val _isConnecting = MutableStateFlow(false)
    val isConnecting: StateFlow<Boolean> = _isConnecting.asStateFlow()

    private val _isDemoMode = MutableStateFlow(true)
    val isDemoMode: StateFlow<Boolean> = _isDemoMode.asStateFlow()

    private val _isVoiceListening = MutableStateFlow(false)
    val isVoiceListening: StateFlow<Boolean> = _isVoiceListening.asStateFlow()

    private val _isBackgroundVoiceServiceActive = MutableStateFlow(false)
    val isBackgroundVoiceServiceActive: StateFlow<Boolean> = _isBackgroundVoiceServiceActive.asStateFlow()

    private val _lastVoiceTranscript = MutableStateFlow("")
    val lastVoiceTranscript: StateFlow<String> = _lastVoiceTranscript.asStateFlow()

    private val _assistantResponseText = MutableStateFlow("Tap the microphone and say something, or ask to create tasks and save memories!")
    val assistantResponseText: StateFlow<String> = _assistantResponseText.asStateFlow()

    private val _consoleLogs = MutableStateFlow<List<String>>(emptyList())
    val consoleLogs: StateFlow<List<String>> = _consoleLogs.asStateFlow()

    // Chats inside selected contact
    private val _activeChatId = MutableStateFlow<String?>(null)
    val activeChatId: StateFlow<String?> = _activeChatId.asStateFlow()

    private val _activeChatMessages = MutableStateFlow<List<Pair<String, Boolean>>>(emptyList())
    val activeChatMessages: StateFlow<List<Pair<String, Boolean>>> = _activeChatMessages.asStateFlow()

    // Local TextToSpeech engine
    private var tts: TextToSpeech? = null
    private var isTtsInitialized = false

    // Local lists for demo mode
    private val demoMemories = mutableListOf<MemoryItem>()
    private val demoSubjects = mutableListOf<SubjectItem>()
    private val demoVoiceRequests = mutableListOf<VoiceRequestItem>()
    private val demoChats = mutableListOf<ChatItem>()
    private val demoChatMessages = mutableMapOf<String, MutableList<Pair<String, Boolean>>>()

    init {
        // Initialize TTS
        tts = TextToSpeech(application, this)

        // Populate beautiful starting mock data for Demo Mode
        setupDemoData()

        // Restore the last selected profile and keep Firebase listeners aligned with it.
        viewModelScope.launch {
            repository.selectedProfile.collect { state ->
                val selectedId = state?.selectedProfileId
                if (!selectedId.isNullOrBlank()) {
                    firebaseRepository.start(selectedId)
                }
            }
        }

        viewModelScope.launch {
            selectedProfile.collect { profile ->
                if (profile != null) {
                    _isDemoMode.value = false
                    addLog("Profile changed: '${profile.displayName}'. Connecting to Firestore-backed profile...")
                    refreshAll()
                } else {
                    firebaseRepository.stop()
                    _isDemoMode.value = true
                    addLog("No active profile selected. Running in local Demo Simulator mode.")
                    _status.value = ServerStatus(
                        connected = false,
                        serverTime = System.currentTimeMillis(),
                        whatsappStatus = "Waiting for Firebase profile",
                        activeProfileName = "None",
                        llmStatus = "Offline",
                        activeSubjectsCount = 0,
                        memoriesCount = 0,
                        recentLogs = emptyList()
                    )
                    _memories.value = emptyList()
                    _subjects.value = emptyList()
                    _voiceRequests.value = emptyList()
                    _chats.value = emptyList()
                }
            }
        }
    }

    fun startFirebaseListening(profileId: String? = null) {
        firebaseRepository.start(profileId)
    }

    fun stopFirebaseListening() {
        firebaseRepository.stop()
    }

    fun setVoiceListening(listening: Boolean) {
        _isVoiceListening.value = listening
    }

    private fun addLog(message: String) {
        val timeStamp = java.text.SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(java.util.Date())
        val formattedLog = "[$timeStamp] $message"
        _consoleLogs.update { (listOf(formattedLog) + it).take(100) }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = tts?.setLanguage(Locale.US)
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                Log.e("TTS", "Language not supported or missing components")
            } else {
                isTtsInitialized = true
                addLog("Local voice engine initialized successfully.")
            }
        } else {
            Log.e("TTS", "Initialization failed")
        }
    }

    fun speak(text: String) {
        if (isTtsInitialized) {
            addLog("Speaking out loud: \"$text\"")
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "WA_ASSISTANT")
        } else {
            addLog("Voice synthesizer is not ready yet.")
        }
    }

    fun toggleDemoMode(enabled: Boolean) {
        _isDemoMode.value = enabled
        if (enabled) {
            addLog("Switched manually to Demo Simulator Mode.")
            loadDemoData()
        } else {
            addLog("Attempting connection to the selected Firebase profile...")
            viewModelScope.launch {
                val active = selectedProfile.value
                if (active != null) {
                    refreshAll()
                } else {
                    addLog("Cannot disable Demo Mode: No Firebase profile is selected yet.")
                    _isDemoMode.value = true
                }
            }
        }
    }

    fun toggleBackgroundVoiceService(context: android.content.Context, enabled: Boolean) {
        _isBackgroundVoiceServiceActive.value = enabled
        val intent = android.content.Intent(context, com.example.BackgroundVoiceService::class.java)
        if (enabled) {
            try {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                addLog("Background voice alerts enabled successfully.")
            } catch (e: Exception) {
                _isBackgroundVoiceServiceActive.value = false
                addLog("Failed to start background alerts service: ${e.localizedMessage}")
            }
        } else {
            context.stopService(intent)
            addLog("Background voice alerts disabled.")
        }
    }

    private fun setupDemoData() {
        demoMemories.add(MemoryItem("m1", "Victor's nickname is Vic.", System.currentTimeMillis() - 7200000))
        demoMemories.add(MemoryItem("m2", "Victor prefers coffee with a splash of oat milk.", System.currentTimeMillis() - 17200000))
        demoMemories.add(MemoryItem("m3", "Mac server runs Qwen-2.5-35B-Instruct inside LM Studio.", System.currentTimeMillis() - 86400000))

        demoSubjects.add(SubjectItem("s1", "Deploy the updated WhatsApp script", "Needs review of YAML elements", "active", System.currentTimeMillis() - 3600000, "Victor"))
        demoSubjects.add(SubjectItem("s2", "Resolve the accessibility container bug", "Already parsed correctly on Sonoma", "resolved", System.currentTimeMillis() - 7200000, "Victor"))
        demoSubjects.add(SubjectItem("s3", "Sync local memories with Cloud Storage", "Postponed until next version", "canceled", System.currentTimeMillis() - 86400000, "Arthur"))

        demoVoiceRequests.add(
            VoiceRequestItem(
                id = "v1",
                kind = "ask",
                title = "Confirm the appointment",
                body = "Victor, the clinic replied. Can I confirm Thursday at 14:00?",
                status = "pending",
                createdAt = System.currentTimeMillis() - 180000
            )
        )
        demoVoiceRequests.add(
            VoiceRequestItem(
                id = "v2",
                kind = "speak",
                title = "Morning reminder",
                body = "Good morning. Time to leave for the appointment in 20 minutes.",
                status = "handled",
                createdAt = System.currentTimeMillis() - 5400000,
                handledAt = System.currentTimeMillis() - 5380000
            )
        )
        demoVoiceRequests.add(
            VoiceRequestItem(
                id = "v3",
                kind = "ask",
                title = "Handled request",
                body = "Did you already receive the payment receipt?",
                status = "handled",
                createdAt = System.currentTimeMillis() - 9000000,
                handledAt = System.currentTimeMillis() - 8700000,
                responseText = "Yes, I got it."
            )
        )

        demoChats.add(ChatItem("c1", "Victor (Client)", 0, "Sounds great, assistant!", System.currentTimeMillis() - 60000))
        demoChats.add(ChatItem("c2", "Arthur Wads", 2, "Is the server running yet?", System.currentTimeMillis() - 3600000))
        demoChats.add(ChatItem("c3", "Development Group", 0, "Pull request merged.", System.currentTimeMillis() - 7200000))

        demoChatMessages["c1"] = mutableListOf(
            "Hello, assistant! Are you receiving notifications?" to false,
            "Yes, Victor! Polling live WhatsApp messages now." to true,
            "Sounds great, assistant!" to false
        )

        demoChatMessages["c2"] = mutableListOf(
            "Hey!" to false,
            "Is the server running yet?" to false
        )

        demoChatMessages["c3"] = mutableListOf(
            "Review code for accessibility mappings." to false,
            "Pull request merged." to false
        )
    }

    private fun loadDemoData() {
        _memories.value = ArrayList(demoMemories)
        _subjects.value = ArrayList(demoSubjects)
        _voiceRequests.value = ArrayList(demoVoiceRequests)
        _chats.value = ArrayList(demoChats)

        // Simulated server status
        _status.value = ServerStatus(
            connected = true,
            serverTime = System.currentTimeMillis(),
            whatsappStatus = "Active (Demo Polling)",
            activeProfileName = "Emulator Hub",
            llmStatus = "Qwen 3.6 35B (Local LM Studio Simulator)",
            activeSubjectsCount = demoSubjects.count { it.status == "active" },
            memoriesCount = demoMemories.size,
            recentLogs = listOf(
                "Polling WhatsApp Web notifications for 3 active profiles...",
                "Processed voice query from client: 'Any unresolved subjects?'",
                "LM Studio returned content for task planning (Qwen 3.6 35B)",
                "Local SQLite database stored and synchronized 3 subjects, 3 memories."
            )
        )
    }

    // Dynamic operations dispatcher
    fun refreshAll() {
        val currentProfile = selectedProfile.value
        if (_isDemoMode.value || currentProfile == null) {
            loadDemoData()
            return
        }
        val activeSubjectsCount = _subjects.value.count { it.status == "active" }
        val memoriesCount = _memories.value.size
        _status.value = ServerStatus(
            connected = true,
            serverTime = System.currentTimeMillis(),
            whatsappStatus = "Firestore profile ready",
            activeProfileName = currentProfile.displayName,
            llmStatus = if (currentProfile.isAutoStart) "Auto-start enabled" else "Auto-start disabled",
            activeSubjectsCount = activeSubjectsCount,
            memoriesCount = memoriesCount,
            recentLogs = _consoleLogs.value.take(5)
        )
    }

    fun selectProfile(profileId: String) {
        viewModelScope.launch(Dispatchers.IO) {
            repository.selectProfile(profileId)
            firebaseRepository.start(profileId)
        }
    }

    // Memories CRUD
    fun addMemory(content: String) {
        if (_isDemoMode.value) {
            val item = MemoryItem(UUID.randomUUID().toString(), content, System.currentTimeMillis())
            demoMemories.add(0, item)
            _memories.value = ArrayList(demoMemories)
            addLog("Memory saved locally: \"$content\"")
            refreshDemoStatus()
        } else {
            val profile = selectedProfile.value ?: return
            viewModelScope.launch(Dispatchers.IO) {
                try {
                    firebaseRepository.addMemory(profile.id, content)
                    addLog("Memory uploaded successfully: \"$content\"")
                    refreshAll()
                } catch (e: Exception) {
                    addLog("Failed to save memory to Firestore. ${e.localizedMessage}")
                }
            }
        }
    }

    fun deleteMemory(id: String) {
        if (_isDemoMode.value) {
            demoMemories.removeAll { it.id == id }
            _memories.value = ArrayList(demoMemories)
            addLog("Memory deleted.")
            refreshDemoStatus()
        } else {
            val profile = selectedProfile.value ?: return
            viewModelScope.launch(Dispatchers.IO) {
                try {
                    firebaseRepository.deleteMemory(profile.id, id)
                    addLog("Memory $id deleted in Firestore.")
                    refreshAll()
                } catch (e: Exception) {
                    addLog("Failed to delete memory from Firestore. ${e.localizedMessage}")
                }
            }
        }
    }

    // Subjects (Tasks) CRUD
    fun addSubject(title: String, notes: String, linkedContact: String? = null) {
        if (_isDemoMode.value) {
            val item = SubjectItem(
                id = UUID.randomUUID().toString(),
                title = title,
                notes = notes,
                status = "active",
                creationTime = System.currentTimeMillis(),
                linkedContactName = linkedContact
            )
            demoSubjects.add(0, item)
            _subjects.value = ArrayList(demoSubjects)
            addLog("Subject created locally: \"$title\"")
            refreshDemoStatus()
        } else {
            val profile = selectedProfile.value ?: return
            viewModelScope.launch(Dispatchers.IO) {
                try {
                    firebaseRepository.addSubject(profile.id, title, notes, linkedContact)
                    addLog("Subject created: \"$title\"")
                    refreshAll()
                } catch (e: Exception) {
                    addLog("Failed to create subject in Firestore. ${e.localizedMessage}")
                }
            }
        }
    }

    fun updateSubjectStatus(id: String, status: String) {
        if (_isDemoMode.value) {
            val index = demoSubjects.indexOfFirst { it.id == id }
            if (index != -1) {
                val current = demoSubjects[index]
                demoSubjects[index] = current.copy(status = status)
                _subjects.value = ArrayList(demoSubjects)
                addLog("Subject updated: Status is now \"$status\" for subject \"${current.title}\"")
                refreshDemoStatus()
            }
        } else {
            val profile = selectedProfile.value ?: return
            viewModelScope.launch(Dispatchers.IO) {
                try {
                    firebaseRepository.updateSubjectStatus(profile.id, id, status)
                    addLog("Subject $id updated to status $status")
                    refreshAll()
                } catch (e: Exception) {
                    addLog("Failed to update subject in Firestore. ${e.localizedMessage}")
                }
            }
        }
    }

    private fun refreshDemoStatus() {
        _status.update { current ->
            current?.copy(
                activeSubjectsCount = demoSubjects.count { it.status == "active" },
                memoriesCount = demoMemories.size
            )
        }
    }

    fun acknowledgeVoiceRequest(requestId: String, responseText: String? = null) {
        if (_isDemoMode.value) {
            val index = demoVoiceRequests.indexOfFirst { it.id == requestId }
            if (index != -1) {
                val current = demoVoiceRequests[index]
                if (current.status != "handled") {
                    demoVoiceRequests[index] = current.copy(
                        status = "handled",
                        handledAt = System.currentTimeMillis(),
                        responseText = responseText ?: current.responseText
                    )
                    _voiceRequests.value = ArrayList(demoVoiceRequests)
                    addLog("Voice request handled locally: \"${current.title}\"")
                }
            }
        }
    }

    // Select Chat and sync messages
    fun selectChat(chatId: String) {
        _activeChatId.value = chatId
        if (_isDemoMode.value) {
            val selectList = demoChatMessages[chatId] ?: mutableListOf()
            _activeChatMessages.value = ArrayList(selectList)
        } else {
            // In a real setup, we could load from a separate message list endpoint or let it show recent from notifications
            val chat = chats.value.find { it.id == chatId }
            if (chat != null) {
                _activeChatMessages.value = listOf(chat.lastMessage to false)
            }
        }
    }

    // Send chat message
    fun sendChatMessage(chatId: String, text: String) {
        if (text.isBlank()) return

        if (_isDemoMode.value) {
            val list = demoChatMessages[chatId] ?: mutableListOf()
            list.add(text to true)
            demoChatMessages[chatId] = list
            _activeChatMessages.value = ArrayList(list)

            // Update chat last message
            val chatIdx = demoChats.indexOfFirst { it.id == chatId }
            if (chatIdx != -1) {
                val currentChat = demoChats[chatIdx]
                demoChats[chatIdx] = currentChat.copy(lastMessage = text, timestamp = System.currentTimeMillis())
                _chats.value = ArrayList(demoChats)
            }
            addLog("Sent WhatsApp message: \"$text\"")

            // Simulate quick response from assistant or contact
            viewModelScope.launch {
                kotlinx.coroutines.delay(1500)
                val reply = "No worries, Vic! Copied and saved."
                list.add(reply to false)
                demoChatMessages[chatId] = list
                if (_activeChatId.value == chatId) {
                    _activeChatMessages.value = ArrayList(list)
                }
                if (chatIdx != -1) {
                    val currentChat = demoChats[chatIdx]
                    demoChats[chatIdx] = currentChat.copy(lastMessage = reply, timestamp = System.currentTimeMillis())
                    _chats.value = ArrayList(demoChats)
                }
                addLog("Received WhatsApp reply: \"$reply\"")
            }
        } else {
            addLog("Chat sending is not wired to Firestore yet.")
        }
    }

    // Process Voice Prompt
    fun sendVoicePrompt(transcript: String) {
        if (transcript.isBlank()) return
        _lastVoiceTranscript.value = transcript
        _assistantResponseText.value = "Thinking..."

        if (_isDemoMode.value) {
            // Run a smart, rule-based local assistant simulation!
            viewModelScope.launch {
                kotlinx.coroutines.delay(1000)
                val cleanTranscript = transcript.lowercase(Locale.getDefault())
                val reply: String
                val spokenText: String

                when {
                    "remember" in cleanTranscript || "salvar lembrança" in cleanTranscript || "lembrar" in cleanTranscript -> {
                        val content = transcript.replace("remember", "", ignoreCase = true)
                            .replace("salvar lembrança", "", ignoreCase = true)
                            .replace("lembrar que", "", ignoreCase = true).trim()
                        val saveContent = if (content.length > 3) content else "Victor said: \"$transcript\""
                        addMemory(saveContent)
                        reply = "Memory saved successfully: \"$saveContent\""
                        spokenText = "I've saved that memory for you, Vic!"
                    }
                    "task" in cleanTranscript || "tarefa" in cleanTranscript || "criar tarefa" in cleanTranscript || "add subject" in cleanTranscript -> {
                        val title = transcript.replace("create task", "", ignoreCase = true)
                            .replace("criar tarefa", "", ignoreCase = true)
                            .replace("task", "", ignoreCase = true)
                            .replace("tarefa ID", "", ignoreCase = true).trim()
                        val taskTitle = if (title.length > 3) title else "Review pending items from Victor's voice"
                        addSubject(taskTitle, "Created via Voice Command")
                        reply = "Subject task added: \"$taskTitle\""
                        spokenText = "Okay, I have created the subject task '$taskTitle'!"
                    }
                    "who is" in cleanTranscript || "quem é" in cleanTranscript || "lembranças" in cleanTranscript || "memories" in cleanTranscript -> {
                        val count = demoMemories.size
                        reply = "You have $count memories saved. The most recent is about: \"${demoMemories.firstOrNull()?.content ?: "Empty"}\""
                        spokenText = "You have $count memories saved. The last one is: \"${demoMemories.firstOrNull()?.content ?: "None"}\""
                    }
                    "unresolved" in cleanTranscript || "pendentes" in cleanTranscript || "tasks" in cleanTranscript || "tarefas" in cleanTranscript -> {
                        val count = demoSubjects.count { it.status == "active" }
                        reply = "There are $count active tasks pending. The top one is: \"${demoSubjects.firstOrNull { it.status == "active" }?.title ?: "None"}\""
                        spokenText = "You have $count active subjects left to resolve."
                    }
                    else -> {
                        reply = "I parsed your query: \"$transcript\". Processing through simulated Qwen 3.6 35B. Memory and subjects remain unchanged."
                        spokenText = "I heard you say: \"$transcript\". Ask me to save a memory or create a task, and I'll execute it!"
                    }
                }

                _assistantResponseText.value = reply
                speak(spokenText)
            }
        } else {
            val profile = selectedProfile.value ?: return
            viewModelScope.launch(Dispatchers.IO) {
                try {
                    firebaseRepository.queueVoicePrompt(profile.id, transcript)
                    _assistantResponseText.value = "Queued in Firestore: \"$transcript\""
                    speak("I queued that request for the selected profile.")
                    refreshAll()
                } catch (e: Exception) {
                    val errorText = "Failed to queue voice prompt in Firestore. ${e.localizedMessage}"
                    addLog(errorText)
                    _assistantResponseText.value = "Local response: I heard \"$transcript\" but could not queue it."
                    speak("Sorry, I heard you say $transcript, but I couldn't queue it to Firestore.")
                }
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        tts?.stop()
        tts?.shutdown()
    }
}
