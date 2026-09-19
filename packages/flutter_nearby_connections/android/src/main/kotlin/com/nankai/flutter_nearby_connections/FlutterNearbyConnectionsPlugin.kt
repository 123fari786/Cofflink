package com.nankai.flutter_nearby_connections

import android.app.Activity
import android.content.*
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.annotation.NonNull
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.Strategy
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.system.exitProcess

const val SERVICE_ID = "flutter_nearby_connections"

const val initNearbyService = "init_nearby_service"
const val startAdvertisingPeer = "start_advertising_peer"
const val startBrowsingForPeers = "start_browsing_for_peers"

const val stopAdvertisingPeer = "stop_advertising_peer"
const val stopBrowsingForPeers = "stop_browsing_for_peers"

const val invitePeer = "invite_peer"
const val disconnectPeer = "disconnect_peer"

const val sendMessage = "send_message"

const val INVOKE_CHANGE_STATE_METHOD = "invoke_change_state_method"
const val INVOKE_MESSAGE_RECEIVE_METHOD = "invoke_message_receive_method"

const val NEARBY_RUNNING = "nearby_running"

/** FlutterNearbyConnectionsPlugin */
class FlutterNearbyConnectionsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var locationHelper: LocationHelper? = null
    private lateinit var activity: Activity
    private var binding: ActivityPluginBinding? = null
    private lateinit var callbackUtils: CallbackUtils

    private lateinit var localDeviceName: String
    private lateinit var strategy: Strategy
    private lateinit var connectionsClient: ConnectionsClient
    private lateinit var serviceBindManager: ServiceBindManager
    private var isBind = false

    private val viewTypeId = "flutter_nearby_connections"

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, viewTypeId)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            initNearbyService -> {
                Log.d("nearby_connections", "initNearbyService")
                callbackUtils = CallbackUtils(channel, activity)
                connectionsClient = Nearby.getConnectionsClient(activity)
                serviceBindManager = ServiceBindManager(activity, channel, callbackUtils)
                serviceBindManager.bindService()

                localDeviceName = if (call.argument<String>("deviceName").isNullOrEmpty())
                    Build.MANUFACTURER + " " + Build.MODEL
                else
                    call.argument<String>("deviceName")!!

                strategy = when (call.argument<Int>("strategy")) {
                    0 -> Strategy.P2P_CLUSTER
                    1 -> Strategy.P2P_STAR
                    else -> Strategy.P2P_POINT_TO_POINT
                }

                locationHelper?.requestLocationPermission(result)
            }

            startAdvertisingPeer -> {
                Log.d("nearby_connections", "startAdvertisingPeer")
                serviceBindManager.mService?.startAdvertising(strategy, localDeviceName)
            }

            startBrowsingForPeers -> {
                Log.d("nearby_connections", "startBrowsingForPeers")
                serviceBindManager.mService?.startDiscovery(strategy)
            }

            stopAdvertisingPeer -> {
                Log.d("nearby_connections", "stopAdvertisingPeer")
                serviceBindManager.mService?.stopAdvertising()
                serviceBindManager.unbindService()
                result.success(true)
            }

            stopBrowsingForPeers -> {
                Log.d("nearby_connections", "stopDiscovery")
                serviceBindManager.mService?.stopDiscovery()
                serviceBindManager.unbindService()
                result.success(true)
            }

            invitePeer -> {
                Log.d("nearby_connections", "invitePeer")
                val deviceId = call.argument<String>("deviceId")
                val displayName = call.argument<String>("deviceName")

                if (deviceId != null && displayName != null) {
                    serviceBindManager.mService?.connect(deviceId, displayName)
                } else {
                    result.error("INVALID_ARGUMENT", "deviceId or deviceName is null", null)
                }
            }

            disconnectPeer -> {
                Log.d("nearby_connections", "disconnectPeer")
                val deviceId = call.argument<String>("deviceId")
                if (deviceId != null) {
                    serviceBindManager.mService?.disconnect(deviceId)
                    callbackUtils.updateStatus(deviceId = deviceId, state = notConnected)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "deviceId is null", null)
                }
            }

            sendMessage -> {
                Log.d("nearby_connections", "sendMessage")
                val deviceId = call.argument<String>("deviceId")
                val message = call.argument<String>("message")

                if (deviceId != null && message != null) {
                    serviceBindManager.mService?.sendStringPayload(deviceId, message)
                } else {
                    result.error("INVALID_ARGUMENT", "deviceId or message is null", null)
                }
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        serviceBindManager.mService?.stopAdvertising()
        serviceBindManager.mService?.stopDiscovery()
        serviceBindManager.unbindService()
        locationHelper = null
        exitProcess(0)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        activity = binding.activity
        locationHelper = LocationHelper(binding.activity)
        locationHelper?.let {
            binding.addActivityResultListener(it)
            binding.addRequestPermissionsResultListener(it)
        }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {
        locationHelper?.let {
            binding?.removeRequestPermissionsResultListener(it)
            binding?.removeActivityResultListener(it)
        }
        binding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {}
}
