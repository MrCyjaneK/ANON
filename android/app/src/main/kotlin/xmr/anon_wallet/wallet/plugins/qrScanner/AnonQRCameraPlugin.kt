package xmr.anon_wallet.wallet.plugins.qrScanner


import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.util.Log
import android.view.Surface
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.app.ActivityCompat.shouldShowRequestPermissionRationale
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import anon.xmr.app.anon_wallet.BuildConfig
import com.google.common.util.concurrent.ListenableFuture
import com.m2049r.xmrwallet.model.WalletManager
import com.sparrowwallet.hummingbird.ResultType
import com.sparrowwallet.hummingbird.UR
import com.sparrowwallet.hummingbird.URDecoder
import com.sparrowwallet.hummingbird.UREncoder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.view.TextureRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import xmr.anon_wallet.wallet.AnonWallet
import xmr.anon_wallet.wallet.AnonWallet.IMPORT_OUTPUT_FILE
import xmr.anon_wallet.wallet.AnonWallet.UR_MAX_FRAGMENT_LENGTH
import xmr.anon_wallet.wallet.AnonWallet.UR_MIN_FRAGMENT_LENGTH
import xmr.anon_wallet.wallet.MainActivity
import xmr.anon_wallet.wallet.channels.AnonMethodChannel
import xmr.anon_wallet.wallet.model.UrRegistryTypes
import java.io.File
import java.util.concurrent.Executors


class AnonQRCameraPlugin(
    private val activity: MainActivity, messenger: BinaryMessenger, lifecycle: Lifecycle
) : FlutterPlugin, AnonMethodChannel(messenger, "anon_camera", lifecycle), EventChannel.StreamHandler {


    private val qrEventChannel = EventChannel(
        messenger, "anon_camera:events"
    )
    private var eventSink: EventSink? = null
    private val cameraExecutor = Executors.newSingleThreadExecutor()
    private val REQUIRED_PERMISSIONS = arrayOf(Manifest.permission.CAMERA)
    private var registry: TextureRegistry? = null
    private var cameraProviderFuture: ListenableFuture<ProcessCameraProvider> = ProcessCameraProvider.getInstance(activity)
    private var camera: Camera? = null
    private var preview: Preview? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var decoder = URDecoder()


    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        registry = binding.textureRegistry
        qrEventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        stopCamera()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startCam" -> startCam(call, result)
            "stopCam" -> stopCamera()
            "checkPermissionState" -> checkPermissionState(call, result)
            "requestPermission" -> requestPermission()
            "createUR" -> createURFrames(call, result)
        }
    }

    private fun checkPermissionState(call: MethodCall, result: Result) {
        result.success(isPermissionGranted())
    }

    private fun requestPermission() {
        if (ContextCompat.checkSelfPermission(
                activity, Manifest.permission.CAMERA
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            startCamera(null)
        } else if (shouldShowRequestPermissionRationale(activity, Manifest.permission.CAMERA)) {
            activity.startActivity(Intent().apply {
                action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                data = Uri.fromParts("package", BuildConfig.APPLICATION_ID, null)
            })
        } else {
            ActivityCompat.requestPermissions(activity, REQUIRED_PERMISSIONS, 2)
        }
    }

    fun onRequestPermissionsResult() {
        if (isPermissionGranted()) {
            startCamera(null)
        } else {

        }
    }


    private fun startCam(call: MethodCall, result: Result) {
        if (isPermissionGranted()) {
            decoder = URDecoder()
            startCamera(result)
        } else {
            result.error("1", "PERMISSION", null)
        }
    }

    private fun createURFrames(call: MethodCall, result: Result) {
        val filePath: String
        val urType: UrRegistryTypes?
        if (call.hasArgument("fpath") && call.argument<String>("fpath") != null) {
            filePath = call.argument<String>("fpath")!!
        } else {
            result.error("0", "NO FILE PATH", null)
            return;
        }
        if (call.hasArgument("type") && call.argument<String>("type") != null) {
            urType = UrRegistryTypes.fromString(call.argument<String>("type")!!)
            if (urType == null) {
                result.error("0", "Invalid Type", null)
                return
            }
        } else {
            result.error("0", "No Type", null)
            return
        }
        val frames = arrayListOf<String>()
        scope.launch {
            withContext(Dispatchers.IO) {
                Log.i(TAG, "createURFrames: ${filePath}")
                val data = File(filePath).readBytes()
                val ur = UR.fromBytes(urType.type, data)
                val encoder = UREncoder(ur, UR_MAX_FRAGMENT_LENGTH, UR_MIN_FRAGMENT_LENGTH, 0)
                while (!encoder.isComplete) {
                    val frame = encoder.nextPart()
                    frames.add(frame)
                }
                Log.i(TAG, "createURFrames: $frames")
                result.success(frames)
            }
        }
    }

    private val qrAnalyzer = QrCodeAnalyzer { qrResult ->
        scope.launch(Dispatchers.IO) {
            val resultQR = qrResult.text
            if (resultQR.lowercase().startsWith("ur:")) {
                if (decoder.result == null) {
                    val decoded = decoder.receivePart(resultQR)
                    if (decoded) {
                        if (decoder.expectedPartCount != 0) {
                            withContext(Dispatchers.Main) {
                                eventSink?.success(
                                    hashMapOf(
                                        "estimatedPercentComplete" to decoder.estimatedPercentComplete,
                                        "expectedPartCount" to decoder.expectedPartCount,
                                        "processedPartsCount" to decoder.processedPartsCount,
                                        "receivedPartIndexes" to decoder.receivedPartIndexes.toIntArray().toList(),
                                    )
                                )
                            }
                        }
                        val urResult = decoder.result
                        if (urResult != null && urResult.type == ResultType.SUCCESS) {
                            withContext(Dispatchers.Main) {
                                eventSink?.success(
                                    hashMapOf(
                                        "estimatedPercentComplete" to decoder.estimatedPercentComplete,
                                        "expectedPartCount" to decoder.expectedPartCount,
                                        "processedPartsCount" to decoder.processedPartsCount,
                                        "receivedPartIndexes" to decoder.receivedPartIndexes.toIntArray().toList(),
                                    )
                                )
                            }
                            val resultMap = hashMapOf(
                                "estimatedPercentComplete" to decoder.estimatedPercentComplete,
                                "expectedPartCount" to decoder.expectedPartCount,
                                "processedPartsCount" to decoder.processedPartsCount,
                                "receivedPartIndexes" to decoder.receivedPartIndexes.toIntArray().toList(),
                                "urType" to urResult.ur.type,
                                "urError" to null,
                            );
                            //TODO: Handle different types of URs
                            if (decoder.processedPartsCount == decoder.expectedPartCount) {
                                
                                handleURTypes(urResult, resultMap)
                            }
                        }
                    }
                } else {
                    val urResult = decoder.result
                    if (urResult != null && urResult.type == ResultType.SUCCESS) {
                        withContext(Dispatchers.Main) {
                            eventSink?.success(
                                hashMapOf(
                                    "estimatedPercentComplete" to decoder.estimatedPercentComplete,
                                    "expectedPartCount" to decoder.expectedPartCount,
                                    "processedPartsCount" to decoder.processedPartsCount,
                                    "receivedPartIndexes" to decoder.receivedPartIndexes.toIntArray().toList(),
                                )
                            )
                        }
                        val resultMap = hashMapOf(
                            "estimatedPercentComplete" to decoder.estimatedPercentComplete,
                            "expectedPartCount" to decoder.expectedPartCount,
                            "processedPartsCount" to decoder.processedPartsCount,
                            "receivedPartIndexes" to decoder.receivedPartIndexes.toIntArray().toList(),
                            "urType" to urResult.ur.type,
                            "urError" to null,
                        );
                        //TODO: Handle different types of URs
                        if (decoder.processedPartsCount == decoder.expectedPartCount) {
                            handleURTypes(urResult, resultMap)
                        }
                    } else {
                        withContext(Dispatchers.Main) {
                            eventSink?.success(
                                hashMapOf(
                                    "result" to qrResult.text
                                )
                            )
                        }
                    }
                }
            } else {
                withContext(Dispatchers.Main) {
                    eventSink?.success(
                        hashMapOf(
                            "result" to qrResult.text
                        )
                    )
                }
            }
        }
    }

    private suspend fun handleURTypes(urResult: URDecoder.Result, resultMap: HashMap<String, Any?>) = withContext(Dispatchers.IO) {

        when (urResult.ur.type) {
            UrRegistryTypes.XMR_OUTPUT.type -> {
                val file = File(activity.cacheDir, IMPORT_OUTPUT_FILE)
                if (!file.exists()) {
                    file.createNewFile()
                }
                file.writeBytes(urResult.ur.toBytes())
                withContext(Dispatchers.Main) {
                    eventSink?.success(
                        resultMap.apply {
                            put("progress", true)
                        }
                    )
                }
                WalletManager.getInstance().wallet.setTrustedDaemon(true)
                val outImportStatus = WalletManager.getInstance().wallet.importOutputsJ(file.absolutePath)
                withContext(Dispatchers.Main) {
                    eventSink?.success(
                        resultMap.apply {
                            put("progress", false)
                            put("urResult", outImportStatus)
                        }
                    )
                }
            }
            UrRegistryTypes.XMR_KEY_IMAGE.type -> {
                val file = File(activity.cacheDir, AnonWallet.IMPORT_KEY_IMAGE_FILE)
                if (!file.exists()) {
                    file.createNewFile()
                }
                withContext(Dispatchers.Main) {
                    eventSink?.success(
                        resultMap.apply {
                            put("progress", true)
                        }
                    )
                }
                file.writeBytes(urResult.ur.toBytes())
                val keyImageImport = WalletManager.getInstance().wallet.importKeyImages(file.absolutePath)
                withContext(Dispatchers.Main) {
                    eventSink?.success(
                        resultMap.apply {
                            put("progress", false)
                            put("urResult", keyImageImport)
                        }
                    )
                }
            }
            UrRegistryTypes.XMR_TX_UNSIGNED.type -> {
                Log.i(TAG, "handleURTypes: ${urResult.type}")
                val file = File(activity.cacheDir, AnonWallet.IMPORT_UNSIGNED_TX_FILE)
                if (!file.exists()) {
                    file.createNewFile()
                }
                Log.i(TAG, "handleURTypes: ${file.absolutePath}")
                file.writeBytes(urResult.ur.toBytes())
                withContext(Dispatchers.Main) {
                    eventSink?.success(
                        resultMap.apply {
                            put("urResult", file.absolutePath)
                        }
                    )
                }
            }
            UrRegistryTypes.XMR_TX_SIGNED.type -> {
                val file = File(activity.cacheDir, AnonWallet.IMPORT_SIGNED_TX_FILE)
                if (!file.exists()) {
                    file.createNewFile()
                }
                file.writeBytes(urResult.ur.toBytes())
                withContext(Dispatchers.Main) {
                    eventSink?.success(
                        resultMap.apply {
                            put("urResult", file.absolutePath)
                        }
                    )
                }
            }
            else -> {
                withContext(Dispatchers.Main) {
                    eventSink?.success(
                        resultMap.apply {
                            put("urError", "Unsupported UR type")
                        }
                    )
                }
            }
        }
    }

    private fun startCamera(result: Result?) {
        decoder = URDecoder()
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            cameraProvider!!.unbindAll()

            textureEntry = registry?.createSurfaceTexture()

            val cameraSelector = CameraSelector.Builder().requireLensFacing(CameraSelector.LENS_FACING_BACK).build()

            val surfaceProvider = Preview.SurfaceProvider { request ->
                val texture = textureEntry!!.surfaceTexture()
                texture.setDefaultBufferSize(
                    request.resolution.width, request.resolution.height
                )
                val surface = Surface(texture)
                request.provideSurface(surface, cameraExecutor) {}
            }

            val previewBuilder = Preview.Builder()
            preview = previewBuilder.build().apply { setSurfaceProvider(surfaceProvider) }

            val imageAnalysis = ImageAnalysis.Builder().setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST).build().also {
                it.setAnalyzer(cameraExecutor, qrAnalyzer)
            }

            camera = cameraProvider?.bindToLifecycle(
                activity as LifecycleOwner, cameraSelector, preview, imageAnalysis
            )

            val resolution = preview?.resolutionInfo!!.resolution
            val portrait = camera!!.cameraInfo.sensorRotationDegrees % 180 == 0
            val width = resolution.width.toDouble()
            val height = resolution.height.toDouble()

            if (textureEntry != null) {
                eventSink?.success(
                    hashMapOf(
                        "id" to textureEntry!!.id(),
                        "width" to if (portrait) width else height,
                        "height" to if (portrait) height else width,
                    )
                )
                result?.success( hashMapOf(
                    "id" to textureEntry!!.id(),
                    "width" to if (portrait) width else height,
                    "height" to if (portrait) height else width,
                ))
            } else {
                result?.error("0","Unable to get camera texture",null)
            }

        }, ContextCompat.getMainExecutor(activity))
    }

    private fun isPermissionGranted() = REQUIRED_PERMISSIONS.all {
        ContextCompat.checkSelfPermission(activity, it) == PackageManager.PERMISSION_GRANTED
    }

    private fun stopCamera() {
        val owner = activity as LifecycleOwner
        camera?.cameraInfo?.torchState?.removeObservers(owner)
        cameraProvider?.unbindAll()
        textureEntry?.release()
        camera = null
        preview = null
        textureEntry = null
        cameraProvider = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {

    }

    companion object {
        const val REQUEST_CODE = 12;
        private const val TAG = "AnonQRCameraPlugin"
    }
}
