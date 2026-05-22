package com.example.data

import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.flow.Flow
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import java.util.concurrent.TimeUnit

class ProfileRepository(private val profileDao: ProfileDao) {

    val allProfiles: Flow<List<ConnectionProfile>> = profileDao.getAllProfilesFlow()
    val activeProfile: Flow<ConnectionProfile?> = profileDao.getActiveProfileFlow()

    private val moshi = Moshi.Builder()
        .addLast(KotlinJsonAdapterFactory())
        .build()

    private val okHttpClient = OkHttpClient.Builder()
        .connectTimeout(4, TimeUnit.SECONDS)
        .readTimeout(4, TimeUnit.SECONDS)
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.HEADERS
        })
        .build()

    fun getApiService(profile: ConnectionProfile): ApiService {
        val rawUrl = profile.baseUrl
        val formattedUrl = if (rawUrl.endsWith("/")) rawUrl else "$rawUrl/"
        return Retrofit.Builder()
            .baseUrl(formattedUrl)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .client(okHttpClient)
            .build()
            .create(ApiService::class.java)
    }

    suspend fun getActiveProfileSync(): ConnectionProfile? = profileDao.getActiveProfile()

    suspend fun addProfile(profile: ConnectionProfile) {
        val id = profileDao.insertProfile(profile)
        if (profile.isActive) {
            profileDao.selectActiveProfile(id.toInt())
        }
    }

    suspend fun selectActiveProfile(profileId: Int) {
        profileDao.selectActiveProfile(profileId)
    }

    suspend fun deleteProfile(profile: ConnectionProfile) {
        profileDao.deleteProfile(profile)
    }
}
