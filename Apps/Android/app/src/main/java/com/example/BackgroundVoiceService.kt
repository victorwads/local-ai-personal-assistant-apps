package com.example

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.speech.tts.TextToSpeech
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.data.*
import kotlinx.coroutines.*
import java.util.Locale

class BackgroundVoiceService : Service(), TextToSpeech.OnInitListener {

    private var tts: TextToSpeech? = null
    private var isTtsReady = false
    private val serviceJob = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)

    private lateinit var db: AppDatabase
    private lateinit var repository: ProfileRepository
    private val firebaseRepository = FirebaseAssistantRepository()

    private val CHANNEL_ID = "BackgroundVoiceAlertsChannel"
    private val NOTIFICATION_ID = 8821

    // Simulated messages for Demo sandbox mode
    private val demoAlerts = listOf(
        "Push notification from Victor: Hello! Please checkout the Sonoma accessibility controller, the WhatsApp flow is active.",
        "System alert: Mac host living room Sonoma is now online and polling WhatsApp.",
        "WhatsApp message from Arthur: Vic, did you finalize the task mapping subject we talked about?",
        "Push alert: Core memory registered successfully: Victor's preferred IDE is Android Studio.",
        "System notification: Background voice assistant link is synced and listening for remote requests."
    )
    private var demoIndex = 0

    override fun onCreate() {
        super.onCreate()
        Log.d("BackgroundVoiceService", "Creating service...")
        db = AppDatabase.getDatabase(applicationContext)
        repository = ProfileRepository(db.selectedProfileDao())

        // Create notification channel
        createNotificationChannel()

        // Setup TTS
        tts = TextToSpeech(this, this)

        // Start Foreground Service immediately to fulfill Oreo+ background executing mandate
        val notification = createNotification("Voice synchronization active")
        startForeground(NOTIFICATION_ID, notification)

        // Start background polling coroutine loop
        startBackgroundPolling()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "WA Assistant Background Voice",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Speaks remote WhatsApp incoming alerts and tasks aloud synchronously in the background"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(contentText: String): Notification {
        val stopIntent = Intent(this, BackgroundVoiceService::class.java).apply {
            action = "STOP_SERVICE"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("WA Assistant Remote")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Disable", stopPendingIntent)
            .build()
    }

    private fun startBackgroundPolling() {
        serviceScope.launch {
            // Keep track of read message IDs to avoid repeating
            val spokenMessageIds = mutableSetOf<String>()
            var currentProfileId: String? = null
            var iterationCount = 0

            while (isActive) {
                try {
                    val profileId = repository.getSelectedProfileSync()?.selectedProfileId
                    if (!profileId.isNullOrBlank()) {
                        if (profileId != currentProfileId) {
                            currentProfileId = profileId
                            firebaseRepository.start(profileId)
                            spokenMessageIds.clear()
                        }
                        Log.d("BackgroundVoiceService", "Polling Firestore voice events for selected profile...")
                        val list = firebaseRepository.voiceEvents.value
                        if (list.isNotEmpty()) {
                            for (event in list) {
                                if (event.id !in spokenMessageIds) {
                                    val text = event.text ?: event.prompt ?: event.transcript
                                    if (!text.isNullOrBlank()) {
                                        speakAloud(text)
                                        spokenMessageIds.add(event.id)
                                        if (spokenMessageIds.size > 200) {
                                            spokenMessageIds.remove(spokenMessageIds.first())
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (currentProfileId != null) {
                            currentProfileId = null
                            firebaseRepository.stop()
                            spokenMessageIds.clear()
                        }
                        // Demo sandbox mode incoming simulated activity
                        iterationCount++
                        // Every ~45 seconds (3 iterations * 15 sec delay) simulate a push notification
                        if (iterationCount % 3 == 0) {
                            val simulatedText = demoAlerts[demoIndex % demoAlerts.size]
                            demoIndex++
                            speakAloud(simulatedText)
                        }
                    }
                } catch (e: Exception) {
                    Log.e("BackgroundVoiceService", "Error in service processing loop", e)
                }

                // Poll every 15 seconds
                delay(15000L)
            }
        }
    }

    private fun speakAloud(text: String) {
        if (isTtsReady) {
            Log.d("BackgroundVoiceService", "TTS Speaking background push: $text")
            tts?.speak(text, TextToSpeech.QUEUE_ADD, null, "BG_PUSH_ALERT")
        } else {
            Log.w("BackgroundVoiceService", "TTS not initialized, drop speech alert: $text")
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = tts?.setLanguage(Locale.US)
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                Log.e("BackgroundVoiceService", "English language in voice engine is not supported/missing")
            } else {
                isTtsReady = true
                Log.d("BackgroundVoiceService", "Background voice alert TTS Ready.")
                speakAloud("Background voice alerts configured successfully!")
            }
        } else {
            Log.e("BackgroundVoiceService", "Voice synthesizer failed to init.")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP_SERVICE") {
            Log.d("BackgroundVoiceService", "Stopping service via user action...")
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d("BackgroundVoiceService", "Destroying background service...")
        serviceJob.cancel()
        tts?.stop()
        tts?.shutdown()
    }
}
