
package com.example.sendora

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.WifiManager
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.sendora/wifi_direct"
    private lateinit var wifiP2pManager: WifiP2pManager
    private lateinit var wifiManager: WifiManager
    private lateinit var channel: WifiP2pManager.Channel
    private lateinit var methodChannel: MethodChannel

    // A list to hold discovered peers
    private val discoveredPeers = mutableListOf<WifiP2pDevice>()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        wifiP2pManager = getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager
        channel = wifiP2pManager.initialize(this, mainLooper, null)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startDiscovery" -> {
                    enableWifi()
                    startDiscovery()
                    result.success("Discovery started")
                }
                "stopDiscovery" -> {
                    stopDiscovery()
                    result.success("Discovery stopped")
                }
                "generateNetworkDetails" -> {
                    val ssid = "Sendora_${System.currentTimeMillis() % 10000}"
                    val password = "Pass_${System.currentTimeMillis() % 10000}"
                    val networkDetails = mapOf("ssid" to ssid, "password" to password)
                    result.success(networkDetails)
                }
                "connectToPeer" -> {
                    val peerAddress = call.argument<String>("address")
                    if (peerAddress != null) {
                        connectToPeer(peerAddress)
                        result.success("Connecting to peer")
                    } else {
                        result.error("INVALID_PARAMETERS", "Address is required", null)
                    }
                }
                "checkConnectionStatus" -> {
                    checkConnectionStatus(result)
                }
                else -> result.notImplemented()
            }
        }

        registerReceiver(wifiP2pReceiver, IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
        })
    }

    private fun enableWifi() {
        if (!wifiManager.isWifiEnabled) {
            wifiManager.isWifiEnabled = true
        }
    }

    private fun startDiscovery() {
        wifiP2pManager.discoverPeers(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.d("WIFI_P2P", "Discovery started")
            }

            override fun onFailure(reasonCode: Int) {
                Log.e("WIFI_P2P", "Discovery failed: $reasonCode")
            }
        })
    }

    private fun stopDiscovery() {
        wifiP2pManager.stopPeerDiscovery(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.d("WIFI_P2P", "Discovery stopped")
            }

            override fun onFailure(reasonCode: Int) {
                Log.e("WIFI_P2P", "Failed to stop discovery: $reasonCode")
            }
        })
    }

    private fun connectToPeer(peerAddress: String) {
        val config = WifiP2pConfig().apply {
            deviceAddress = peerAddress
            groupOwnerIntent = 0
        }
        wifiP2pManager.connect(channel, config, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.d("WIFI_P2P", "Connection initiated to $peerAddress")
            }

            override fun onFailure(reasonCode: Int) {
                Log.e("WIFI_P2P", "Connection failed: $reasonCode")
            }
        })
    }

    private fun checkConnectionStatus(result: MethodChannel.Result) {
        wifiP2pManager.requestConnectionInfo(channel) { info ->
            if (info.groupFormed) {
                result.success("Connected to ${info.groupOwnerAddress.hostAddress}")
            } else {
                result.success("Not connected")
            }
        }
    }

    private val wifiP2pReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                    updatePeerList()
                }
                WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                    wifiP2pManager.requestConnectionInfo(channel, connectionInfoListener)
                }
            }
        }
    }

    private fun updatePeerList() {
        wifiP2pManager.requestPeers(channel) { peersList ->
            // Store discovered peers in a list
            discoveredPeers.clear()
            discoveredPeers.addAll(peersList.deviceList)
            // Send the discovered peers back to Flutter
            val peers = peersList.deviceList.map { peer ->
                mapOf("name" to peer.deviceName, "address" to peer.deviceAddress)
            }
            methodChannel.invokeMethod("onPeersAvailable", peers)
        }
    }

    private val connectionInfoListener = WifiP2pManager.ConnectionInfoListener { info ->
        if (info.groupFormed && info.isGroupOwner) {
            Log.d("WIFI_P2P", "Connected as group owner")
            methodChannel.invokeMethod("onConnected", info.groupOwnerAddress?.hostAddress)
        } else if (info.groupFormed) {
            Log.d("WIFI_P2P", "Connected as peer")
            methodChannel.invokeMethod("onConnected", info.groupOwnerAddress?.hostAddress)
        } else {
            Log.d("WIFI_P2P", "Disconnected")
            methodChannel.invokeMethod("onDisconnected", null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(wifiP2pReceiver)
    }
}