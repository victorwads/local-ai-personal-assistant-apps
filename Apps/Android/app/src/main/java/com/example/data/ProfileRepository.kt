package com.example.data

import kotlinx.coroutines.flow.Flow

class ProfileRepository(private val selectedProfileDao: SelectedProfileDao) {
    val selectedProfile: Flow<SelectedProfileEntity?> = selectedProfileDao.getSelectedProfileFlow()

    suspend fun getSelectedProfileSync(): SelectedProfileEntity? = selectedProfileDao.getSelectedProfile()

    suspend fun selectProfile(profileId: String) {
        selectedProfileDao.upsertSelectedProfile(
            SelectedProfileEntity(selectedProfileId = profileId)
        )
    }

    suspend fun clearSelectedProfile() {
        selectedProfileDao.upsertSelectedProfile(
            SelectedProfileEntity(selectedProfileId = null)
        )
    }
}
