package com.example.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.google.firebase.auth.FirebaseAuth

@Composable
fun FirebaseAuthGate(viewModel: MainViewModel) {
    val auth = remember { FirebaseAuth.getInstance() }
    var currentUser by remember { mutableStateOf(auth.currentUser) }

    DisposableEffect(auth) {
        val listener = FirebaseAuth.AuthStateListener { firebaseAuth ->
            currentUser = firebaseAuth.currentUser
        }
        auth.addAuthStateListener(listener)
        onDispose { auth.removeAuthStateListener(listener) }
    }

    if (currentUser != null) {
        LaunchedEffect(currentUser?.uid) {
            viewModel.startFirebaseListening()
        }
        AppNavigation(viewModel = viewModel)
    } else {
        LaunchedEffect(Unit) {
            viewModel.stopFirebaseListening()
        }
        GoogleSignInGate(
            onSignedIn = { currentUser = auth.currentUser }
        )
    }
}
