package com.example.ui

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log

suspend fun startSpeechRecognition(context: Context, viewModel: MainViewModel) {
    val speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, java.util.Locale.getDefault())
        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        putExtra("android.speech.extra.ENABLE_FORMATTING", "android.speech.extra.FORMATTING_SENSITIVE_TO_SCENARIO")
        putExtra("android.speech.extra.DICTATION_MODE", true)
    }

    speechRecognizer.setRecognitionListener(object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            viewModel.setVoiceListening(true)
        }

        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEndOfSpeech() {
            viewModel.setVoiceListening(false)
        }

        override fun onError(error: Int) {
            viewModel.setVoiceListening(false)
            Log.w("VoiceScreen", "STT error: $error")
        }

        override fun onResults(results: Bundle?) {
            val transcript = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull().orEmpty()
            if (transcript.isNotBlank()) {
                viewModel.sendVoicePrompt(formatPunctuation(transcript))
            }
            viewModel.setVoiceListening(false)
        }

        override fun onPartialResults(partialResults: Bundle?) {}
        override fun onEvent(eventType: Int, params: Bundle?) {}
    })

    speechRecognizer.startListening(intent)
}
