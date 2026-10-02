package com.masteralanlab.avalon.models

import com.masteralanlab.avalon.service.models.VpnOptions
import com.google.gson.annotations.SerializedName

data class SharedState(
    val startTip: String = "Starting VPN...",
    val stopTip: String = "Stopping VPN...",
    val currentProfileName: String = "Avalon",
    val stopText: String = "Stop",
    val onlyStatisticsProxy: Boolean = false,
    val vpnOptions: VpnOptions? = null,
    val setupParams: SetupParams? = null,
)

data class SetupParams(
    @SerializedName("profile-id") val profileId: Long = 0,
    @SerializedName("test-url")
    val testUrl: String,
    @SerializedName("selected-map")
    val selectedMap: Map<String, String>,
)
