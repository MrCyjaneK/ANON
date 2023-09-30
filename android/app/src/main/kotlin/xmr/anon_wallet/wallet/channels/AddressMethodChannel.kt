package xmr.anon_wallet.wallet.channels

import androidx.lifecycle.Lifecycle
import com.m2049r.xmrwallet.data.Subaddress
import com.m2049r.xmrwallet.model.WalletManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import xmr.anon_wallet.wallet.channels.WalletEventsChannel.sendEvent
import xmr.anon_wallet.wallet.model.getLatestSubaddress
import xmr.anon_wallet.wallet.model.toHashMap
import xmr.anon_wallet.wallet.model.walletToHashMap
import com.m2049r.xmrwallet.model.Wallet.ConnectionStatus

class AddressMethodChannel(messenger: BinaryMessenger, lifecycle: Lifecycle) :
    AnonMethodChannel(messenger, CHANNEL_NAME, lifecycle) {


    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "renameAddress" -> renameAddress(call, result)
            "getSubAddresses" -> getSubAddresses(result)
            "deriveNewSubAddress" -> deriveNewSubAddress(call, result)
        }
    }

    private fun getSubAddresses(result: Result) {
        sendEvent(getSubAddressesEvent())
        result.success(null);
    }


    private fun deriveNewSubAddress(call: MethodCall, result: Result) {
        scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    WalletManager.getInstance().wallet?.let {
                        it.addSubaddress(it.accountIndex, "Subaddress #${it.numSubaddresses}")
                        sendEvent(getSubAddressesEvent())
                        sendEvent(it.walletToHashMap())
                        result.success(true)
                    }
                } catch (e: Exception) {
                    result.error("0", "Unable to derive new subaddress ${e.message}", null)
                }
            }
        }
    }

    private fun renameAddress(call: MethodCall, result: Result) {
        val wallet = WalletManager.getInstance().wallet
        if (wallet != null) {
            val label = call.argument<String>("label")
            val addressIndex = call.argument<Int>("addressIndex")
            val accountIndex = call.argument<Int>("accountIndex")
            if (label == null || addressIndex == null || accountIndex == null) {
                result.error("invalid arg", "invalid method call params", null);
            }
            scope.launch {
                withContext(Dispatchers.IO) {
                    wallet.setSubaddressLabel(
                        addressIndex!!,
                        label
                    )
                    wallet.refreshHistory()
                    wallet.store()
                    sendEvent(wallet.walletToHashMap())
                    sendEvent(getSubAddressesEvent())
                }
            }
        }
    }

    companion object {
        const val CHANNEL_NAME = "address.channel"
        public fun getSubAddressesEvent(): HashMap<String, Any> {
            val wallet = WalletManager.getInstance().wallet
            return hashMapOf(
                "EVENT_TYPE" to "SUB_ADDRESSES",
                "addresses" to getAllSubAddresses().map { it.toHashMap() }.toList(),
                "height" to wallet.blockChainHeight,
                "isConnected" to wallet.connectionStatus.equals(ConnectionStatus.ConnectionStatus_Connected),
            )
        }

        private fun getAllSubAddresses(): List<Subaddress> {
            val wallet = WalletManager.getInstance().wallet
            val subAddresses = arrayListOf<Subaddress>()
            for (i in 0 until wallet.numSubaddresses) {
                subAddresses.add(wallet.getSubaddressObject(i))
            }
            wallet.getLatestSubaddress()?.let {
                if (subAddresses.indexOf(it) == -1) subAddresses.add(it)
            }
            return subAddresses
                .apply {
                    this.removeIf { it.addressIndex == 0 && it.totalAmount != 0L }
                }
                .onEach { item ->
                    if (item.label.isNullOrEmpty()) {
                        item.label = "Subaddress #${item.addressIndex}"
                    }
                }
                .distinctBy { it.address }.sortedBy { it.addressIndex }.reversed()
        }
    }
}