package xmr.anon_wallet.wallet.model

import android.util.Log
import com.m2049r.xmrwallet.data.Subaddress
import com.m2049r.xmrwallet.model.Wallet
import xmr.anon_wallet.wallet.channels.WalletEventsChannel

fun Wallet.getLastUnusedIndex(): Int {
    var lastUsedSubaddress = 0
    val subaddress = arrayListOf<Subaddress>()
    for (i in 0 until this.numSubaddresses) {
        subaddress.add(this.getSubaddressObject(i))
    }
    subaddress.forEach {
        //Skip primary and find unused subaddress
        if (it.totalAmount == 0L && subaddress.indexOf(it)!= 0) {
            return subaddress.indexOf(it)
        }
    }
    for (info in this.history.all) {
        if (info.addressIndex > lastUsedSubaddress) lastUsedSubaddress = info.addressIndex
    }
    return lastUsedSubaddress + 1
}

fun Wallet.getLatestSubaddress(): Subaddress? {
    val lastUsedSubaddress = getLastUnusedIndex()
    val address = this.getSubaddressObject(lastUsedSubaddress)
    if (lastUsedSubaddress == this.numSubaddresses) {
        this.addSubaddress(accountIndex, "Subaddress #${address.addressIndex}")
    }
    return address
}

fun Subaddress.toHashMap(): HashMap<String, Any> {
    return hashMapOf(
        "address" to (this.address ?: ""),
        "addressIndex" to this.addressIndex,
        "accountIndex" to this.accountIndex,
        "displayLabel" to (this.displayLabel ?: ""),
        "label" to (this.label ?: ""),
        "totalAmount" to (this.totalAmount),
        "squashedAddress" to this.squashedAddress,
    );
}

fun Wallet.walletToHashMap(): HashMap<String, Any> {
    val nextAddress = if (this.getLatestSubaddress() != null) this.getLatestSubaddress()?.toHashMap()!! else hashMapOf<String, String>()
    var connection = "disconnected";
    var error = "";
    if (WalletEventsChannel.initialized) {
        connection = "${this.fullStatus}"
        error = this.fullStatus.errorString
    }
    Log.i("Wallet", "Wallet FullStatus: ${connection} $error")
    return hashMapOf(
        "connection" to (connection),
        "connectionError" to (error),
        "name" to this.name,
        "address" to this.address,
        "secretViewKey" to this.secretViewKey,
        "balance" to this.balanceAll,
        "balanceAll" to this.balanceAll,
        "unlockedBalanceAll" to this.unlockedBalanceAll,
        "unlockedBalance" to this.unlockedBalance,
        "currentAddress" to nextAddress,
        "isSynchronized" to this.isSynchronized,
        "blockChainHeight" to this.blockChainHeight,
        "daemonBlockChainHeight" to this.daemonBlockChainHeight,
        "daemonBlockChainTargetHeight" to this.daemonBlockChainTargetHeight,
        "numSubaddresses" to this.numSubaddresses,
        "seedLanguage" to this.seedLanguage,
        "restoreHeight" to this.restoreHeight,
        "transactions" to this.history.all.sortedByDescending { it.timestamp }.sortedBy { !it.isPending }.map { it.toHashMap() }.toList(),
        "EVENT_TYPE" to "WALLET",
    )
}
