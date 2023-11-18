package xmr.anon_wallet.wallet.channels

import android.util.Log
import androidx.lifecycle.Lifecycle
import anon.xmr.app.anon_wallet.BuildConfig
import com.m2049r.xmrwallet.model.NetworkType
import com.m2049r.xmrwallet.model.WalletManager
import com.m2049r.xmrwallet.util.KeyStoreHelper
import com.m2049r.xmrwallet.utils.RestoreHeight
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import xmr.anon_wallet.wallet.AnonWallet
import xmr.anon_wallet.wallet.MainActivity
import xmr.anon_wallet.wallet.channels.WalletEventsChannel.sendEvent
import xmr.anon_wallet.wallet.model.walletToHashMap
import xmr.anon_wallet.wallet.restart
import xmr.anon_wallet.wallet.services.NodeManager
import xmr.anon_wallet.wallet.utils.AnonPreferences
import xmr.anon_wallet.wallet.utils.Prefs
import java.io.File
import java.net.SocketException
import java.util.Calendar
import android.net.Uri
import android.content.Intent
import android.provider.Settings

class WalletMethodChannel(messenger: BinaryMessenger, lifecycle: Lifecycle, private val activity: MainActivity) : AnonMethodChannel(messenger, CHANNEL_NAME, lifecycle) {

    init {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    NodeManager.setNode()
                } catch (socket: SocketException) {
                    Log.i(TAG, "SocketException :${socket.message} ")
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "create" -> createWallet(call, result)
            "walletState" -> walletState(call, result)
            "isViewOnly" -> isViewOnly(call, result)
            "openWallet" -> openWallet(call, result)
            "viewWalletInfo" -> viewWalletInfo(call, result)
            "rescan" -> rescan(call, result)
            "refresh" -> refresh(call, result)
            "startSync" -> startSync(call, result)
            "getTxKey" -> getTxKey(call, result)
            "exportOutputs" -> exportOutputs(call, result)
            "importKeyImages" -> importKeyImages(call, result)
            "submitTransaction" -> submitTransaction(call, result)
            "setTxUserNotes" -> setTxUserNotes(call, result)
            "isSynchronized" -> isSynchronized(call, result)
            "wipeWallet" -> wipeWallet(call, result)
            "importOutputsJ" -> importOutputsJ(call, result)
            "exportKeyImages" -> exportKeyImages(result)
            "signAndExportJ" -> signAndExportJ(call, result)
            "optimizeBattery" -> optimizeBattery(call, result)
            "setTrustedDaemon" -> setTrustedDaemon(call, result)
            "lock" -> lock(call, result)
            "store" -> store(call, result)
            "unlock" -> unlock(call, result)
            "getUtxos" -> getUtxos(call, result)
        }
    }

    private fun optimizeBattery(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                val intent = Intent();
                intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                intent.setAction(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                intent.setData(Uri.parse("package:" + AnonWallet.getAppContext().getPackageName()));
                AnonWallet.getAppContext().startActivity(intent);
            }
        }
    }

    private fun importOutputsJ(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                if (call.hasArgument("filename")) {
                    try {
                        val filename = call.argument<String>("filename") as String
                        val eo = WalletManager.getInstance().wallet.importOutputsJ(filename)
                        result.success(eo)
                    } catch (e: Exception) {
                        result.error("1", e.message, "")
                        throw CancellationException(e.message)
                    }
                } else {
                    result.error("0", "invalid params", null)
                }
            }
        }
    }

    private fun exportKeyImages(result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val file = File(AnonWallet.getAppContext().cacheDir, AnonWallet.EXPORT_KEY_IMAGE_FILE)
                    val eo = WalletManager.getInstance().wallet.exportKeyImages(file.absolutePath, true)
                    if (eo) {
                        result.success(file.absolutePath)
                    } else {
                        result.error("1", "exportKeyImages failed", "")
                    }
                } catch (e: Exception) {
                    result.error("1", e.message, "")
                    throw CancellationException(e.message)
                }
            }
        }
    }

    private fun signAndExportJ(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                if (call.hasArgument("inputFile") && call.hasArgument("outputFile")) {
                    try {
                        val inputFile = call.argument<String>("inputFile") as String
                        val outputFile = call.argument<String>("outputFile") as String
                        val eo = WalletManager.getInstance().wallet.signAndExportJ(inputFile, outputFile)
                        result.success(eo)
                    } catch (e: Exception) {
                        result.error("1", e.message, "")
                        throw CancellationException(e.message)
                    }
                } else {
                    result.error("0", "invalid params", null)
                }
            }
        }
    }

    private fun setTrustedDaemon(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                if (call.hasArgument("arg")) {
                    try {
                        val arg = call.argument<Boolean>("arg") as Boolean
                        val eo = WalletManager.getInstance().wallet.setTrustedDaemon(arg)
                        result.success(eo)
                    } catch (e: Exception) {
                        result.error("1", e.message, "")
                        throw CancellationException(e.message)
                    }
                } else {
                    result.error("0", "invalid params", null)
                }
            }
        }
    }

    private fun isViewOnly(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    result.success(BuildConfig.VIEW_ONLY)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
        }
    }

    private fun store(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    if (WalletManager.getInstance().wallet == null) {
                        Log.d("WalletMethodChannel.kt", "store(): Wallet is null");
                        throw Exception("Wallet is null.");
                    }
                    WalletManager.getInstance().wallet.store();
                    result.success("Stored");
                } catch (e: Exception) {
                    result.error("0", "Unable to switch to background sync mode.\n${e.message}", null);
                }
            }
        }
    }

    private fun lock(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    if (WalletManager.getInstance().wallet == null) {
                        Log.d("WalletMethodChannel.kt", "lock(): Wallet is null");
                        throw Exception("Wallet is null.");
                    }
                    val bgsyncStatus = WalletManager.getInstance().wallet.startBackgroundSync();
                    if (!bgsyncStatus) {
                        throw Exception("Failed to startBackgroundSync");
                    }
                    result.success("Locked");
                } catch (e: Exception) {
                    result.error("0", "Unable to switch to background sync mode.\n${e.message}", null);
                }
            }
        }
    }

    private fun unlock(call: MethodCall, result: Result) {
        val password = call.argument<String?>("password")
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    if (WalletManager.getInstance().wallet == null) {
                        Log.d("WalletMethodChannel.kt", "lock(): Wallet is null");
                        throw Exception("Wallet is null.");
                    }
                    val bgsyncStatus = WalletManager.getInstance().wallet.stopBackgroundSync(password);
                    if (!bgsyncStatus) {
                        throw Exception("Failed to stopBackgroundSync");
                    }
                    result.success("Unlocked");
                } catch (e: Exception) {
                    result.error("0", "Unable to return from background sync mode.\n${e.message}", null);
                }
            }
        }
    }

    private fun wipeWallet(call: MethodCall, result: Result) {
        val seedPassphrase = call.argument<String?>("seedPassphrase")
        val hash = AnonPreferences(AnonWallet.getAppContext()).passPhraseHash
        val hashedPass = KeyStoreHelper.getCrazyPass(AnonWallet.getAppContext(), seedPassphrase)
        try {
            if (hashedPass == hash) {
                if (WalletManager.getInstance().wallet == null) {
                    result.error("1", "Wallet not initialized", "")
                    return
                }
                scope.launch {
                    withContext(Dispatchers.Default) {
                        AnonPreferences(activity).clearPreferences()
                        //wait for preferences to be cleared
                        delay(600)
                        AnonWallet.walletDir.deleteRecursively()
                        activity.cacheDir.deleteRecursively()
                        withContext(Dispatchers.Main) {
                            activity.restart()
                        }
                    }
                }
            } else {
                result.error("1", "Invalid passphrase", "")
            }
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("1", "Error ${e.message}", e.message)
        }
    }

    private fun viewWalletInfo(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val seedPassphrase = call.argument<String?>("seedPassphrase")
                    val hash = AnonPreferences(AnonWallet.getAppContext()).passPhraseHash
                    val hashedPass = KeyStoreHelper.getCrazyPass(AnonWallet.getAppContext(), seedPassphrase)
                    if (hashedPass == hash) {
                        val wallet = WalletManager.getInstance().wallet
                        result.success(
                            hashMapOf(
                                "address" to wallet.address,
                                "secretViewKey" to wallet.secretViewKey,
                                "seed" to wallet.getSeed(seedPassphrase),
                                "legacySeed" to wallet.getLegacySeed(seedPassphrase),
                                "isPolyseedSupported" to wallet.isPolyseedSupported(seedPassphrase),
                                "spendKey" to wallet.secretSpendKey,
                                "restoreHeight" to wallet.restoreHeight
                            )
                        )
                    } else {
                        result.error("1", "Invalid passphrase", "")
                    }
                } catch (e: Exception) {
                    result.error("2", e.message, "")
                    e.printStackTrace()
                }
            }
        }
    }

    private fun getUtxos(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val wallet = WalletManager.getInstance().wallet
                    val utxos = wallet.getUtxos()
                    // List<CoinsInfo>
                    val hm : HashMap<Int, HashMap<String, Any>> = hashMapOf();
                    var i = 0;
                    for (utxo in utxos) {
                        hm[i] = hashMapOf();
                        hm[i]!!["globalOutputIndex"] = utxo.globalOutputIndex
                        hm[i]!!["spent"] = utxo.isSpent()
                        hm[i]!!["keyImage"] = utxo.keyImage
                        hm[i]!!["amount"] = utxo.amount
                        hm[i]!!["hash"] = utxo.hash
                        hm[i]!!["pubKey"] = utxo.pubKey
                        hm[i]!!["unlocked"] = utxo.isUnlocked()
                        hm[i]!!["localOutputIndex"] = utxo.localOutputIndex
                        i++
                    }
                    result.success(hm)
                } catch (e: Exception) {
                    result.error("2", e.message, "")
                    e.printStackTrace()
                }
            }
        }
    }

    private fun refresh(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                val wallet = WalletManager.getInstance().wallet
                if (wallet != null) {
                    try {
                        WalletEventsChannel.initWalletListeners()
                        wallet.startRefresh()
                        wallet.refresh()
                        wallet.refreshHistory()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("1", "error", "")
                        sendEvent(
                            hashMapOf(
                                "EVENT_TYPE" to "NODE",
                                "status" to "disconnected",
                                "connection_error" to "${e.message}"
                            )
                        )
                        throw CancellationException()
                    }
                } else {
                    result.success(false)
                }
            }
        }
    }

    private fun rescan(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                WalletManager.getInstance().wallet?.let {
                    try {
                        result.success(true)
                        it.rescanBlockchainAsync()
                        it.refreshHistory()
                    } catch (e: Exception) {
                        result.success(false)
                        sendEvent(
                            hashMapOf(
                                "EVENT_TYPE" to "NODE",
                                "status" to "disconnected",
                                "connection_error" to "Error ${e.message}"
                            )
                        )
                    }
                }
            }
        }
    }

    private fun startSync(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                WalletManager.getInstance().wallet
            }
        }
    }

    private fun openWallet(call: MethodCall, result: Result) {
        val walletPassword = call.argument<String>("password")
        val walletFileName = "default"
        val walletFile = File(AnonWallet.walletDir, walletFileName)
        if (walletPassword == null) {
            result.error("INVALID_PASSWORD", "invalid pin", null)
            return
        }
        scope.launch {
            withContext(Dispatchers.IO) {
                if (walletFile.exists()) {
                    try {
                        sendEvent(
                            hashMapOf(
                                "EVENT_TYPE" to "OPEN_WALLET",
                                "state" to true
                            )
                        )
                        // check if we need connected hardware
                        val checkPassword = AnonWallet.getWalletPassword(walletFileName, walletPassword) != null
                        if (!checkPassword) {
                            result.error("1", "Invalid pin", "invalid pin")
                            return@withContext
                        }
                        if (WalletManager.getInstance().daemonAddress == null) {
                            NodeManager.setNode()
                        }
                        if (WalletManager.getInstance().daemonAddress != null) {
                            if (WalletManager.getInstance().daemonAddress.toString().contains(".i2p")) {
                                WalletManager.getInstance().proxy = getProxyI2p()
                            } else {
                                WalletManager.getInstance().proxy = getProxyTor()
                            }
                        }
                        Log.d("WalletMethodChannel.kt", "openWallet(${walletFile.path}, '****', true)")
                        val wallet = WalletManager.getInstance().openWallet(walletFile.path, walletPassword, true)
                        result.success(wallet.walletToHashMap())
                        sendEvent(wallet.walletToHashMap())
                        wallet.refreshHistory()
                        sendEvent(wallet.walletToHashMap())
                        WalletEventsChannel.initWalletListeners()
                        val preferences = AnonPreferences(AnonWallet.getAppContext())
                        val serverUrl = preferences.serverUrl
                        if (WalletManager.getInstance().daemonAddress != null) {
                            Log.d("WalletMethodChannel.kt", WalletManager.getInstance().daemonAddress.toString())
                        } else {
                            Log.d("WalletMethodChannel.kt", "(WalletManager.getInstance().daemonAddress != null): true")
                        }
                        
                        // if (WalletManager.getInstance().daemonAddress.toString().contains(".i2p")) {
                        //     wallet.setProxy(getProxyI2p())
                        // } else {
                        //     wallet.setProxy(getProxyTor())
                        // }

                        WalletManager.getInstance().daemonAddress?.let {
                            if (WalletManager.getInstance().daemonAddress != null) {
                                if (WalletManager.getInstance().daemonAddress.toString().contains(".i2p")) {
                                    WalletEventsChannel.initialized = wallet.init(0, getProxyI2p())
                                } else {
                                    WalletEventsChannel.initialized = wallet.init(0, getProxyTor())
                                }
                            } else {
                                WalletEventsChannel.initialized = wallet.init(0, "")
                            }
                            Prefs.restoreHeight?.let {
                                if (it != 0L)
                                    wallet.restoreHeight = it
                                Prefs.restoreHeight = 0L
                            }
                            
//                            if (WalletEventsChannel.initialized) {
//                                wallet.refreshHistory()
//                            }
                            sendEvent(wallet.walletToHashMap())
                            sendEvent(
                                hashMapOf(
                                    "EVENT_TYPE" to "OPEN_WALLET",
                                    "state" to false
                                )
                            )
                        }
                        sendEvent(wallet.walletToHashMap())
                        sendEvent(
                            hashMapOf(
                                "EVENT_TYPE" to "OPEN_WALLET",
                                "state" to false
                            )
                        )
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.error("WALLET_OPEN_ERROR", e.message, e.localizedMessage)
                    }
                }
            }
        }
    }

    private fun walletState(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.Default) {
                val exist =
                    WalletManager.getInstance().walletExists(File(AnonWallet.walletDir, "default"))
                if (exist) {
                    result.success(2)
                } else {
                    result.success(0)
                }
            }
        }
    }

    private fun createWallet(call: MethodCall, result: Result) {
        if (call.hasArgument("name") && call.hasArgument("password")) {
            val walletName = call.argument<String>("name")
            val walletPin = call.argument<String>("password")
            val seedPhrase = call.argument<String?>("seedPhrase")
            if (walletName == null || walletName.isEmpty()) {
                return result.error(INVALID_ARG, "invalid name parameter", null)
            }
            if (walletPin == null || walletPin.isEmpty()) {
                return result.error(INVALID_ARG, "invalid password parameter", null)
            }
            var restoreHeight = 1L
            scope.launch {
                withContext(Dispatchers.IO) {
                    val cacheFile = File(AnonWallet.walletDir, walletName)
                    val keysFile = File(AnonWallet.walletDir, "$walletName.keys")
                    val addressFile = File(AnonWallet.walletDir, "$walletName.address.txt")
                    //TODO
                    if (addressFile.exists()) {
                        addressFile.delete()
                    }
                    if (keysFile.exists()) {
                        keysFile.delete()
                    }
                    if (cacheFile.exists()) {
                        cacheFile.delete()
                    }
                    //TODO
//                    if (cacheFile.exists() || keysFile.exists() || addressFile.exists()) {
//                        Timber.e("Some wallet files already exist for %s", cacheFile.absolutePath)
//                        result.error(WALLET_EXIST, "Some wallet files already exist for ${cacheFile.absolutePath}", null)
//                        return@withContext
//                    }
                    val newWalletFile = File(AnonWallet.walletDir, walletName)
                    val default = "English"
                    //Close if wallet is already open
                    Log.d("WalletMethodChannel.kt", "closing wallet")
                    WalletManager.getInstance().wallet?.close()
                    // NOTE: I don't think that we really need to set proxy here?
                    // TODO: check for leaks
                    // WalletManager.getInstance().setProxy(getProxy())
                    Log.d("WalletMethodChannel.kt", "Do we leak, checkpoint 1")
                    if (AnonWallet.getNetworkType() == NetworkType.NetworkType_Mainnet) {
                        if (NodeManager.getNode() != null && NodeManager.getNode()?.getHeight() != null) {
                            restoreHeight = NodeManager.getNode()?.getHeight()!!
                        }
                        val restoreDate = Calendar.getInstance()
                        restoreDate.add(Calendar.DAY_OF_MONTH, -4)
                        RestoreHeight.getInstance().getHeight(restoreDate.time)
                    } else {
                        restoreHeight = NodeManager.getNode()?.getHeight() ?: 1L
                    }
                    sendEvent(
                        hashMapOf(
                            "EVENT_TYPE" to "OPEN_WALLET",
                            "state" to true
                        )
                    )
                    Log.d("WalletMethodChannel.kt", "Creating wallet")
                    val wallet = WalletManager.getInstance()
                        .createWallet(newWalletFile, walletPin, seedPhrase, default, restoreHeight)
                    Log.d("WalletMethodChannel.kt", "Wallet created")
                    AnonPreferences(context = AnonWallet.getAppContext()).passPhraseHash = KeyStoreHelper.getCrazyPass(AnonWallet.getAppContext(), seedPhrase)
                    val map = wallet.walletToHashMap()
                    map["seed"] = wallet.getSeed(seedPhrase ?: "")
                    wallet.store()
                    result.success(map)
                    if (AnonPreferences(AnonWallet.getAppContext()).serverUrl != null) {
                        NodeManager.setNode()
                    } else {
                        if (WalletManager.getInstance().reopen()) {
                            WalletEventsChannel.initWalletListeners()
                        }
                    }
                    if (wallet.status.isOk) {
                        wallet.refresh()
                        sendEvent(wallet.walletToHashMap())
                        if (WalletManager.getInstance().daemonAddress != null) {
                            if (WalletManager.getInstance().daemonAddress.toString().contains(".i2p")) {
                                WalletEventsChannel.initialized = wallet.init(0, getProxyI2p())
                            } else {
                                WalletEventsChannel.initialized = wallet.init(0, getProxyTor())
                            }
                        } else {
                            WalletEventsChannel.initialized = wallet.init(0, "")
                        }
                        sendEvent(wallet.walletToHashMap())

                        wallet.refreshHistory()
                        sendEvent(
                            hashMapOf(
                                "EVENT_TYPE" to "OPEN_WALLET",
                                "state" to false
                            )
                        )
                    } else {
                        sendEvent(
                            hashMapOf(
                                "EVENT_TYPE" to "OPEN_WALLET",
                                "state" to false
                            )
                        )
                        result.error(wallet.status.status.name, wallet.status.errorString, null)
                    }
                }
            }.invokeOnCompletion {
                if (it != null) {
                    it.printStackTrace()
                    result.error(ERRORS, it.message, it)
                }
            }
        }
    }

    private fun getProxyTor(): String {
        val prefs = AnonPreferences(AnonWallet.getAppContext());
        Log.d("WalletMethodChannel.kt", "getProxyTor(): ${prefs.proxyServer}:${prefs.proxyPortTor}")
        return if (prefs.proxyPortTor.isNullOrEmpty() || prefs.proxyServer.isNullOrEmpty()) {
            ""
        } else {
            "${prefs.proxyServer}:${prefs.proxyPortTor}"
        }
    }

    private fun getProxyI2p(): String {
        val prefs = AnonPreferences(AnonWallet.getAppContext());
        Log.d("WalletMethodChannel.kt", "getProxyI2p(): ${prefs.proxyServer}:${prefs.proxyPortI2p}")
        return if (prefs.proxyPortI2p.isNullOrEmpty() || prefs.proxyServer.isNullOrEmpty()) {
            ""
        } else {
            "${prefs.proxyServer}:${prefs.proxyPortI2p}"
        }
    }

    private fun exportOutputs(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val file = File(AnonWallet.getAppContext().cacheDir, AnonWallet.EXPORT_OUTPUT_FILE)
                    val eo = WalletManager.getInstance().wallet.exportOutputs(file.absolutePath, true)
                    if (eo) {
                        result.success(file.absolutePath)
                    } else {
                        result.error("1", "Failed to export outputs", "")
                    }
                } catch (e: Exception) {
                    result.error("1", e.message, "")
                    throw CancellationException(e.message)
                }
            }
        }
    }

    private fun importKeyImages(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val path = call.argument<String?>("filename")
                    val file = if (path == null) {
                        File(AnonWallet.getAppContext().cacheDir, AnonWallet.IMPORT_KEY_IMAGE_FILE)
                    } else {
                        File(path)
                    }

                    val eo = WalletManager.getInstance().wallet.importKeyImages(file.absolutePath)
                    result.success(eo)
                } catch (e: Exception) {
                    result.error("1", e.message, "")
                    throw CancellationException(e.message)

                }
            }
        }
    }

    private fun submitTransaction(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                if (call.hasArgument("filename")) {
                    try {
                        val filename = call.argument<String>("filename") as String
                        val eo = WalletManager.getInstance().wallet.submitTransaction(filename)
                        result.success(eo)
                    } catch (e: Exception) {
                        result.error("1", e.message, "")
                        throw CancellationException(e.message)
                    }
                } else {
                    result.error("0", "invalid params", null)
                }
            }
        }
    }
    private fun getTxKey(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                if (call.hasArgument("txId")) {
                    try {
                        val txId = call.argument<String>("txId")
                        val txKey = WalletManager.getInstance().wallet.getTxKey(txId)
                        result.success(txKey)
                    } catch (e: Exception) {
                        result.error("1", e.message, "")
                        throw CancellationException(e.message)
                    }
                } else {
                    result.error("0", "invalid params", null)
                }
            }
        }
    }

    private fun isSynchronized(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    result.success(NodeManager.getNode() == null || WalletManager.getInstance().wallet.isSynchronized)
                } catch (e: Exception) {
                    result.error("1", e.message, "")
                    throw CancellationException(e.message)
                }
            }
        }
    }

    private fun setTxUserNotes(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                if (call.hasArgument("txId") && call.hasArgument("message")) {
                    try {
                        val txId = call.argument<String>("txId")
                        val message = call.argument<String>("message")
                        val success = WalletManager.getInstance().wallet.setUserNote(txId, message)
                        WalletManager.getInstance().wallet.store()
                        WalletManager.getInstance().wallet.refreshHistory()
                        sendEvent(WalletManager.getInstance().wallet.walletToHashMap())
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("1", e.message, "")
                        throw CancellationException(e.message)
                    }
                } else {
                    result.error("0", "invalid params", null)
                }
            }
        }
    }

    companion object {
        private const val TAG = "WalletMethodChannel"
        const val CHANNEL_NAME = "wallet.channel"
        const val WALLET_EVENT_CHANNEL = "wallet.events"
        var backupPath: String? = null
    }

}