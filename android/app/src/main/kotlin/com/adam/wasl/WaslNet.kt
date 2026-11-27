package com.adam.wasl

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.SoftApConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * "شبكة وصل": الموبايل بيفتح شبكة واي فاي لوحده (Local-Only Hotspot — من غير إنترنت)، والتانيين بيدخلوها
 * من جوه التطبيق (WifiNetworkSpecifier — أندرويد 10+، بضغطة موافقة واحدة من النظام).
 *
 * القناة wasl/net:
 *   hostStart → {ssid, pass, sec}   hostStop   hostActive → bool
 *   joinSupported → bool   join {ssid, pass, sec} → bool   leave
 * أحداث لـ Flutter على wasl/system: netLost (الشبكة اللي دخلناها وقعت)، hostLost (النظام قفل الهوت سبوت).
 */
object WaslNet {
    private var channel: MethodChannel? = null
    private lateinit var app: Context
    private val main = Handler(Looper.getMainLooper())

    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null
    private var joinCallback: ConnectivityManager.NetworkCallback? = null

    /** رد Flutter على طلب الدخول اللي لسه مستني (عشان لو خرجنا قبل ما يخلص منسيبش Flutter مستني على طول). */
    private var pendingJoin: ((Boolean) -> Unit)? = null

    private val wifi get() = app.getSystemService(Context.WIFI_SERVICE) as WifiManager
    private val connectivity get() = app.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    fun register(context: Context, messenger: BinaryMessenger) {
        app = context.applicationContext
        val ch = MethodChannel(messenger, "wasl/net")
        channel = ch
        ch.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "hostStart" -> hostStart(result)
                    "hostStop" -> {
                        hostStop()
                        result.success(null)
                    }
                    "hostActive" -> result.success(reservation != null)
                    "joinSupported" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                    "join" -> join(
                        call.argument<String>("ssid") ?: "",
                        call.argument<String>("pass") ?: "",
                        call.argument<Int>("sec") ?: 1,
                        result,
                    )
                    "leave" -> {
                        leave()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: SecurityException) {
                result.error("permission", e.message, null)
            } catch (e: Exception) {
                result.error("error", e.message, null)
            }
        }
    }

    private fun event(name: String) = MainActivity.send(name, emptyMap<String, Any?>())

    // ---------------- فتح الشبكة ----------------

    private fun hostStart(result: MethodChannel.Result) {
        val current = reservation
        if (current != null) {
            result.success(describe(current))
            return
        }
        var answered = false
        fun answer(block: () -> Unit) {
            if (answered) return
            answered = true
            block()
        }
        wifi.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
            override fun onStarted(res: WifiManager.LocalOnlyHotspotReservation) {
                reservation = res
                answer { result.success(describe(res)) }
            }

            override fun onStopped() {
                reservation = null
                event("hostLost")
            }

            override fun onFailed(reason: Int) {
                reservation = null
                val code = when (reason) {
                    WifiManager.LocalOnlyHotspotCallback.ERROR_INCOMPATIBLE_MODE -> "incompatible"
                    WifiManager.LocalOnlyHotspotCallback.ERROR_TETHERING_DISALLOWED -> "disallowed"
                    WifiManager.LocalOnlyHotspotCallback.ERROR_NO_CHANNEL -> "no_channel"
                    else -> "failed"
                }
                answer { result.error(code, "local-only hotspot failed: $reason", null) }
            }
        }, main)
    }

    /** اسم الشبكة والباسورد ونوع التشفير (0 مفتوحة • 1 WPA2 • 2 WPA3 • 3 WPA3 مع WPA2). */
    @Suppress("DEPRECATION")
    private fun describe(res: WifiManager.LocalOnlyHotspotReservation): Map<String, Any?> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val c = res.softApConfiguration
            val ssid = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                c.wifiSsid?.toString()?.removeSurrounding("\"")
            } else {
                c.ssid
            }
            val sec = when (c.securityType) {
                SoftApConfiguration.SECURITY_TYPE_OPEN -> 0
                SoftApConfiguration.SECURITY_TYPE_WPA2_PSK -> 1
                SoftApConfiguration.SECURITY_TYPE_WPA3_SAE -> 2
                SoftApConfiguration.SECURITY_TYPE_WPA3_SAE_TRANSITION -> 3
                else -> 1
            }
            return mapOf("ssid" to ssid, "pass" to c.passphrase, "sec" to sec)
        }
        val c = res.wifiConfiguration
        return mapOf("ssid" to c?.SSID?.removeSurrounding("\""), "pass" to c?.preSharedKey?.removeSurrounding("\""), "sec" to 1)
    }

    private fun hostStop() {
        reservation?.close()
        reservation = null
    }

    // ---------------- دخول شبكة ----------------

    private fun join(ssid: String, pass: String, sec: Int, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("unsupported", "needs Android 10", null)
            return
        }
        leave()
        val spec = WifiNetworkSpecifier.Builder().setSsid(ssid).apply {
            when (sec) {
                0 -> Unit
                2 -> setWpa3Passphrase(pass)
                else -> setWpa2Passphrase(pass)
            }
        }.build()
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(spec)
            .build()
        var answered = false
        val answer: (Boolean) -> Unit = { ok ->
            main.post {
                if (!answered) {
                    answered = true
                    pendingJoin = null
                    result.success(ok)
                }
            }
        }
        pendingJoin = answer
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                // كل الاتصالات الجديدة في التطبيق تمشي على الشبكة دي (مفيهاش إنترنت، وده المطلوب)
                connectivity.bindProcessToNetwork(network)
                answer(true)
            }

            override fun onUnavailable() {
                answer(false)
                joinCallback = null
            }

            override fun onLost(network: Network) {
                connectivity.bindProcessToNetwork(null)
                event("netLost")
            }
        }
        joinCallback = cb
        // النظام بيسأل المستخدم "توصل بالشبكة دي؟" — لو مردش في دقيقة بنعتبرها اترفضت
        connectivity.requestNetwork(request, cb, 60_000)
    }

    private fun leave() {
        pendingJoin?.invoke(false)
        pendingJoin = null
        val cb = joinCallback ?: return
        joinCallback = null
        connectivity.bindProcessToNetwork(null)
        try {
            connectivity.unregisterNetworkCallback(cb)
        } catch (ignored: Exception) {
        }
    }

    /** التطبيق بيقفل: نقفل الشبكة اللي فتحناها ونسيب اللي دخلناها. */
    fun shutdown() {
        hostStop()
        leave()
    }
}
