package com.example.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.google.firebase.auth.FirebaseAuth

@Composable
fun FirebaseAuthGate(viewModel: MainViewModel) {
    val auth = remember { FirebaseAuth.getInstance() }
    var currentUser by remember { mutableStateOf(auth.currentUser) }
    val profiles by viewModel.firebaseProfiles.collectAsStateWithLifecycle()
    val selectedProfile by viewModel.selectedProfile.collectAsStateWithLifecycle()
    var selectedProfileId by rememberSaveable(currentUser?.uid) { mutableStateOf<String?>(null) }
    var confirmedProfileId by rememberSaveable(currentUser?.uid) { mutableStateOf<String?>(null) }

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
        LaunchedEffect(profiles, selectedProfile?.id) {
            if (selectedProfileId == null || profiles.none { it.id == selectedProfileId }) {
                selectedProfileId = selectedProfile?.id ?: profiles.firstOrNull()?.id
            }
        }

        val profileConfirmedThisSession =
            confirmedProfileId != null && selectedProfile?.id == confirmedProfileId

        if (profileConfirmedThisSession) {
            AppNavigation(viewModel = viewModel)
        } else {
            ProfileSelectionScreen(
                firebaseUser = currentUser,
                profiles = profiles,
                selectedProfileId = selectedProfileId,
                onProfileSelected = { selectedProfileId = it },
                onConfirmSelection = {
                    selectedProfileId?.let { profileId ->
                        confirmedProfileId = profileId
                        viewModel.selectProfile(profileId)
                    }
                }
            )
        }
    } else {
        LaunchedEffect(currentUser) {
            viewModel.stopFirebaseListening()
            selectedProfileId = null
            confirmedProfileId = null
        }
        GoogleSignInGate(
            onSignedIn = { currentUser = auth.currentUser }
        )
    }
}
