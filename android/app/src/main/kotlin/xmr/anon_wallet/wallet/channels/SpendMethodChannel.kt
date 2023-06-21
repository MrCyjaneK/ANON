package xmr.anon_wallet.wallet.channels

import androidx.lifecycle.Lifecycle
import com.m2049r.xmrwallet.model.PendingTransaction
import com.m2049r.xmrwallet.model.Wallet
import com.m2049r.xmrwallet.model.WalletManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import xmr.anon_wallet.wallet.AnonWallet
import xmr.anon_wallet.wallet.AnonWallet.ONE_XMR
import xmr.anon_wallet.wallet.model.UrRegistryTypes
import java.io.File
import java.util.Arrays
import android.util.Log

class SpendMethodChannel(messenger: BinaryMessenger, lifecycle: Lifecycle) : AnonMethodChannel(messenger, CHANNEL_NAME, lifecycle) {

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "validate" -> validate(call, result)
            "composeTransaction" -> composeTransaction(call, result)
            "composeAndBroadcast" -> composeAndBroadcast(call, result)
            "composeAndSave" -> composeAndSave(call, result)
            "broadcastSigned" -> broadcastSigned(call, result)
            "loadUnsignedTx" -> loadUnsignedTx(call, result)
            "signUnsignedTx" -> signUnsignedTx(call, result)
            "importTxFile" -> importTxFile(call, result)
            "getExportPath" -> getExportPath(call, result)
        }
    }

    private fun importTxFile(call: MethodCall, result: Result) {
        val unsignedTxFile = File(AnonWallet.getAppContext().cacheDir, AnonWallet.IMPORT_UNSIGNED_TX_FILE)
        val signedTxFile = File(AnonWallet.getAppContext().cacheDir, AnonWallet.IMPORT_SIGNED_TX_FILE)
        val path = call.argument<String?>("filePath") ?: return result.error("0", "Invalid file path", null)
        val type = call.argument<String?>("type") ?: return result.error("0", "Invalid type", null)
        val importFile = File(path)
        when (type) {
            "signed" -> {
                importFile.copyTo(signedTxFile, overwrite = true)
            }
            "unsigned" -> {
                importFile.copyTo(unsignedTxFile, overwrite = true)
            }
            else -> {
                return result.error("0", "Invalid type", null)
            }
        }
        result.success(true);
    }

    private fun signUnsignedTx(call: MethodCall, result: Result) {
        scope.launch(Dispatchers.IO) {
            val unsignedTxFile = File(AnonWallet.getAppContext().cacheDir, AnonWallet.IMPORT_UNSIGNED_TX_FILE)
            val signedTxFile = File(AnonWallet.getAppContext().cacheDir, AnonWallet.EXPORT_SIGNED_TX_FILE)
            if (unsignedTxFile.exists()) {
                val status = WalletManager.getInstance().wallet.signAndExportJ(unsignedTxFile.absolutePath, signedTxFile.absolutePath)
                withContext(Dispatchers.Main) {
                    if (status == "Signed") {
                        return@withContext result.success(
                            hashMapOf(
                                "state" to "success",
                                "status" to "Signed",
                                "errorString" to "",
                            )
                        )
                    } else {
                        return@withContext result.success(
                            hashMapOf(
                                "state" to "error",
                                "status" to "Signed",
                                "errorString" to "Unable to sign tx",
                            )
                        )
                    }
                }
            } else {
                result.error("0", "no unsigned tx file", null)
            }
        }
    }

    private fun getExportPath(call: MethodCall, result: Result) {

        val type = call.argument<String?>("type") ?: return result.error("0", "type is null", null)
        val file = when (UrRegistryTypes.fromString(type)) {
            UrRegistryTypes.XMR_OUTPUT -> File(AnonWallet.getAppContext().cacheDir, AnonWallet.EXPORT_OUTPUT_FILE)
            UrRegistryTypes.XMR_KEY_IMAGE -> File(AnonWallet.getAppContext().cacheDir, AnonWallet.EXPORT_KEY_IMAGE_FILE)
            UrRegistryTypes.XMR_TX_UNSIGNED -> File(AnonWallet.getAppContext().cacheDir, AnonWallet.EXPORT_UNSIGNED_TX_FILE)
            UrRegistryTypes.XMR_TX_SIGNED -> File(AnonWallet.getAppContext().cacheDir, AnonWallet.EXPORT_SIGNED_TX_FILE)
            null -> return result.error("0", "type is null", null)
        }
        result.success(file.absolutePath)
    }

    private fun broadcastSigned(call: MethodCall, result: Result) {
        scope.launch(Dispatchers.IO) {
            val wallet = WalletManager.getInstance().wallet;
            val txFile = File(AnonWallet.getAppContext().cacheDir, AnonWallet.IMPORT_SIGNED_TX_FILE)
            if (txFile.exists()) {
                val status = wallet.submitTransaction(txFile.absolutePath)
                wallet.store()
                wallet.refreshHistory()
                withContext(Dispatchers.Main) {
                    if (status.lowercase().contains("submitted")) {
                        return@withContext result.success(
                            mapOf(
                                "status" to "success",
                                "result" to status
                            )
                        );
                    } else {
                        return@withContext result.error("0", status.ifEmpty { "Unable to broadcast transaction" }, null);
                    }
                }
            } else {
                withContext(Dispatchers.IO) {
                    result.error("1", "no tx file", null)
                }
            }
        }
    }

    private fun loadUnsignedTx(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                val txFile = File(AnonWallet.getAppContext().cacheDir, AnonWallet.IMPORT_UNSIGNED_TX_FILE)
                Log.d("SpendMethodChannel.kt", "txFile: "+txFile.path)
                if (txFile.exists()) {
                    Log.d("SpendMethodChannel.kt", "loadUnsignedTx: start")
                    val unsignedTransaction = WalletManager.getInstance().wallet.loadUnsignedTxJ(txFile.path)
                    Log.d("SpendMethodChannel.kt", "loadUnsignedTx: end")
                    Log.d("SpendMethodChannel.kt", "address: "+unsignedTransaction.address)
                    withContext(Dispatchers.Main) {
                        if (unsignedTransaction != null) {
                            result.success(
                                hashMapOf( 
                                    "fee" to unsignedTransaction.fee,
                                    "amount" to unsignedTransaction.amount,
                                    "address" to unsignedTransaction.address,
                                    "state" to "preview",
                                    "status" to unsignedTransaction.status.toString(),
                                    "txId" to (unsignedTransaction.firstTxIdJ ?: ""),
                                    "txCount" to 0,
                                    "errorString" to unsignedTransaction.errorString,
                                )
                            )
                        } else {
                            result.error("0", "error", null);
                        }
                    }
                } else {
                    withContext(Dispatchers.IO) {
                        result.error("1", "no tx file", null)
                    }
                }
            }
        }
    }

    private fun composeAndBroadcast(call: MethodCall, result: Result) {
        val address = call.argument<String?>("address")
        val amount = call.argument<String>("amount")
        val notes = call.argument<String>("notes")
        val rawKeyImages = call.argument<String>("keyImages")
        val keyImages = arrayListOf<String>()
        keyImages.addAll(rawKeyImages!!.split(","))
        val amountNumeric = Wallet.getAmountFromString(amount)
        if (address == null || amount == null) {
            return result.error("1", "invalid args", null)
        }
        this.scope.launch {
                withContext(Dispatchers.IO) {
                val wallet = WalletManager.getInstance().wallet
                val selectedUtxos = keyImages
                var error = "";
                var txId = "";
                var pendingTx : PendingTransaction?;
                pendingTx = null;
                var success = false;
                try {
                    pendingTx = wallet.createTransaction(address, amountNumeric, 1, PendingTransaction.Priority.Priority_Default, selectedUtxos)
                    txId = pendingTx.firstTxIdJ;
                    success = pendingTx.commit("", true)
                    if (success) {
                        wallet.refreshHistory()
                        wallet.setUserNote(txId, notes)
                    }
                } catch (e: Exception) {
                    error = e.message?: "failed to create transaction";
                }
                wallet.store()
                withContext(Dispatchers.IO) {
                    result.success(
                        hashMapOf(
                            "fee" to pendingTx?.fee,
                            "amount" to pendingTx?.amount,
                            "state" to if (success) "success" else "error",
                            "status" to pendingTx?.status.toString(),
                            "txId" to txId,
                            "txCount" to pendingTx?.txCount,
                            "errorString" to error //.ifEmpty { pendingTx?.errorString },
                        )
                    )
                }
            }
        }
    }

    private fun composeTransaction(call: MethodCall, result: Result) {
        val address = call.argument<String?>("address")
        val amount = call.argument<String>("amount")
        val rawKeyImages = call.argument<String>("keyImages")
        val keyImages = arrayListOf<String>()
        keyImages.addAll(rawKeyImages!!.split(","))
        val amountNumeric = Wallet.getAmountFromString(amount)
        if (address == null || amount == null) {
            return result.error("1", "invalid args", null)
        }
        this.scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val wallet = WalletManager.getInstance().wallet
                    val selectedUtxos = keyImages
                    val pendingTx = wallet.createTransaction(address, amountNumeric, 1, PendingTransaction.Priority.Priority_Default, selectedUtxos)
                    result.success(
                        hashMapOf(
                            "fee" to pendingTx.fee,
                            "amount" to pendingTx.amount,
                            "state" to "preview",
                            "status" to pendingTx.status.toString(),
                            "txId" to (pendingTx.firstTxIdJ ?: ""),
                            "txCount" to pendingTx.txCount,
                            "errorString" to pendingTx.errorString,
                        )
                    )
                } catch (e: Exception) {
                    result.success(
                        hashMapOf(
                            "errorString" to e.message, //.ifEmpty { pendingTx?.errorString },
                        )
                    )
                }
            }
        }
    }

    private fun composeAndSave(call: MethodCall, result: Result) {
        val address = call.argument<String?>("address")
        val amount = call.argument<String>("amount")
        val sign = call.argument<Boolean?>("sign") ?: true
        val amountNumeric = Wallet.getAmountFromString(amount)
        if (address == null || amount == null) {
            return result.error("1", "invalid args", null)
        }
        val rawKeyImages = call.argument<String>("keyImages")
        val keyImages = arrayListOf<String>()
        keyImages.addAll(rawKeyImages!!.split(","))
        this.scope.launch {
            withContext(Dispatchers.IO) {
                val wallet = WalletManager.getInstance().wallet
                val pendingTx = wallet.createTransaction(address, amountNumeric, 1, PendingTransaction.Priority.Priority_Default, keyImages);
                val txId = pendingTx.firstTxIdJ;
                var error = "";
                var success = false
                try {
                    val unsignedTxFile = File(AnonWallet.getAppContext().cacheDir, AnonWallet.EXPORT_UNSIGNED_TX_FILE)
                    success = pendingTx.commit(unsignedTxFile.absolutePath, true)
                    if (sign) {
                        val signedTxPath = File(AnonWallet.getAppContext().cacheDir, AnonWallet.EXPORT_SIGNED_TX_FILE)
                        wallet.signAndExportJ(unsignedTxFile.absolutePath, signedTxPath.absolutePath)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    error = e.message ?: "";
                }
                wallet.store()
                withContext(Dispatchers.Main) {
                    result.success(
                        hashMapOf(
                            "fee" to pendingTx.fee,
                            "amount" to pendingTx.amount,
                            "state" to if (success) "success" else "error",
                            "status" to pendingTx.status.toString(),
                            "txId" to (txId ?: ""),
                            "txCount" to pendingTx.txCount,
                            "errorString" to error.ifEmpty { pendingTx.errorString },
                        )
                    )
                }
            }
        }
    }

    private fun validate(call: MethodCall, result: Result) {
        val address = call.argument<String?>("address")
        val amount = call.argument<String>("amount")
        val wallet = WalletManager.getInstance().wallet
        val funds = wallet.unlockedBalance
        val maxFunds = 1.0 * funds / ONE_XMR
        val amountNumeric = Wallet.getAmountFromString(amount)
        val response = try {
            hashMapOf(
                "address" to Wallet.isAddressValid(address),
                "amount" to (amountNumeric < 0 || amountNumeric > maxFunds)
            )
        } catch (e: Exception) {
            return result.error("0", e.cause?.message, e.message)
        }
        return result.success(response)
    }

    companion object {
        const val CHANNEL_NAME = "spend.channel"
    }

}