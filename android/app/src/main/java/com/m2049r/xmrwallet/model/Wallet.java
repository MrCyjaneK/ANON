/*
 * Copyright (c) 2017 m2049r
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.m2049r.xmrwallet.model;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.m2049r.xmrwallet.data.Subaddress;
import com.m2049r.xmrwallet.data.TxData;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import lombok.Getter;
import timber.log.Timber;
import android.util.Log;

import android.util.Log;

// import kotlin.Pair;
import android.util.Pair;
// Because fuck me. That's why.

import com.m2049r.xmrwallet.model.UnsignedTransaction;

public class Wallet {
    final static public long SWEEP_ALL = Long.MAX_VALUE;

    static {
        System.loadLibrary("monerujo");
    }
    private Coins coins = null;

    static public class Status {
        Status(int status, String errorString) {
            this.status = StatusEnum.values()[status];
            this.errorString = errorString;
        }

        final private StatusEnum status;
        final private String errorString;
        @Nullable
        private ConnectionStatus connectionStatus; // optional

        public StatusEnum getStatus() {
            return status;
        }

        public String getErrorString() {
            return errorString;
        }

        public void setConnectionStatus(@Nullable ConnectionStatus connectionStatus) {
            this.connectionStatus = connectionStatus;
        }

        @Nullable
        public ConnectionStatus getConnectionStatus() {
            return connectionStatus;
        }

        public boolean isOk() {
            return (getStatus() == StatusEnum.Status_Ok)
                    && ((getConnectionStatus() == null) ||
                    (getConnectionStatus() == ConnectionStatus.ConnectionStatus_Connected));
        }

        @Override
        @NonNull
        public String toString() {
            return "Wallet.Status: " + status + "/" + errorString + "/" + connectionStatus;
        }
    }

    private int accountIndex = 0;

    public int getAccountIndex() {
        return accountIndex;
    }

    public void setAccountIndex(int accountIndex) {
        Timber.d("setAccountIndex(%d)", accountIndex);
        this.accountIndex = accountIndex;
        getHistory().setAccountFor(this);
    }

    public String getName() {
        return new File(getPath()).getName();
    }

    private long handle = 0;
    private long listenerHandle = 0;

    Wallet(long handle) {
        this.handle = handle;
    }

    Wallet(long handle, int accountIndex) {
        this.handle = handle;
        this.accountIndex = accountIndex;
    }

    @Getter
    public enum Device {
        Device_Undefined(0, 0),
        Device_Software(50, 200),
        Device_Ledger(5, 20);
        private final int accountLookahead;
        private final int subaddressLookahead;
        Device(int accountLookahead,int subaddressLookahead){
            this.accountLookahead = accountLookahead;
            this.subaddressLookahead = subaddressLookahead;
        }

        public int getAccountLookahead() {
            return accountLookahead;
        }

        public int getSubaddressLookahead() {
            return subaddressLookahead;
        }
    }

    public enum StatusEnum {
        Status_Ok,
        Status_Error,
        Status_Critical
    }

    public enum ConnectionStatus {
        ConnectionStatus_Disconnected,
        ConnectionStatus_Connected,
        ConnectionStatus_WrongVersion
    }

    public native String getSeed(String offset);
    public native String getLegacySeed(String offset);
    public native boolean isPolyseedSupported(String offset);

    public native String getSeedLanguage();

    public native void setSeedLanguage(String language);

    public Status getStatus() {
        return statusWithErrorString();
    }

    public Status getFullStatus() {
        Status walletStatus = statusWithErrorString();
        walletStatus.setConnectionStatus(getConnectionStatus());
        return walletStatus;
    }

    private native Status statusWithErrorString();

    public native synchronized boolean setPassword(String password);

    public String getAddress() {
        return getAddress(accountIndex);
    }

    public String getAddress(int accountIndex) {
        return getAddressJ(accountIndex, 0);
    }

    public String getSubaddress(int addressIndex) {
        return getAddressJ(accountIndex, addressIndex);
    }

    public String getSubaddress(int accountIndex, int addressIndex) {
        return getAddressJ(accountIndex, addressIndex);
    }

    private native String getAddressJ(int accountIndex, int addressIndex);

    public Subaddress getSubaddressObject(int accountIndex, int subAddressIndex) {
        return new Subaddress(accountIndex, subAddressIndex,
                getSubaddress(subAddressIndex), getSubaddressLabel(subAddressIndex));
    }

    public Subaddress getSubaddressObject(int subAddressIndex) {
        Subaddress subaddress = getSubaddressObject(accountIndex, subAddressIndex);
        long amount = 0;
        for (TransactionInfo info : getHistory().getAll()) {
            if ((info.addressIndex == subAddressIndex)
                    && (info.direction == TransactionInfo.Direction.Direction_In)) {
                amount += info.amount;
            }
        }
        subaddress.setAmount(amount);
        return subaddress;
    }

    public native String getPath();

    public NetworkType getNetworkType() {
        return NetworkType.fromInteger(nettype());
    }

    public native int nettype();

//TODO virtual void hardForkInfo(uint8_t &version, uint64_t &earliest_height) const = 0;
//TODO virtual bool useForkRules(uint8_t version, int64_t early_blocks) const = 0;

    public native String getIntegratedAddress(String payment_id);

    public native String getSecretViewKey();

    public native String getSecretSpendKey();

    public boolean store() {
        return store("");
    }

    public native synchronized boolean store(String path);

    public boolean close() {
        disposePendingTransaction();
        return WalletManager.getInstance().close(this);
    }

    public native String getFilename();

    //    virtual std::string keysFilename() const = 0;
    public boolean init(long upper_transaction_size_limit, String proxy_address) {
        String daemon_address = WalletManager.getInstance().getDaemonAddress();
        String daemon_username = WalletManager.getInstance().getDaemonUsername();
        String daemon_password = WalletManager.getInstance().getDaemonPassword();
        Log.d("Wallet.java", "init(");
        if (daemon_address != null) {
            Log.d("Wallet.java", daemon_address.toString());
        } else {
            Log.d("Wallet.java", "daemon_address == null");
            daemon_address = "";
        }
        Log.d("Wallet.java", "upper_transaction_size_limit = 0 (probably)");
        if (daemon_username != null) {
            Log.d("Wallet.java", daemon_username.toString());
        } else {
            Log.d("Wallet.java", "daemon_username == null");
            daemon_username = "";
        }
        if (daemon_password != null) {
            Log.d("Wallet.java", daemon_password.toString());
        } else {
            Log.d("Wallet.java", "daemon_password == null");
            daemon_password = "";
        }
        if (proxy_address != null) {
            Log.d("Wallet.java", proxy_address.toString());
        } else {
            Log.d("Wallet.java", "proxy_address == null");
            proxy_address = "";
        }
        Log.d("Wallet.java", ");");
        return initJ(daemon_address, upper_transaction_size_limit,
                daemon_username, daemon_password,
                proxy_address);
    }

    private native boolean initJ(String daemon_address, long upper_transaction_size_limit,
                                 String daemon_username, String daemon_password,
                                 String proxy_address);

//    virtual bool createWatchOnly(const std::string &path, const std::string &password, const std::string &language) const = 0;
//    virtual void setRefreshFromBlockHeight(uint64_t refresh_from_block_height) = 0;

    public native void setRestoreHeight(long height);

    public native long getRestoreHeight();

    //    virtual void setRecoveringFromSeed(bool recoveringFromSeed) = 0;
//    virtual bool connectToDaemon() = 0;

    public ConnectionStatus getConnectionStatus() {
        int s = getConnectionStatusJ();
        return ConnectionStatus.values()[s];
    }

    private native int getConnectionStatusJ();

//TODO virtual void setTrustedDaemon(bool arg) = 0;
//TODO virtual bool trustedDaemon() const = 0;

     public native boolean setProxyJ(String address);

    public boolean setProxy(String address) {
        Log.d("Wallet.java", "setProxy("+address+")");
        if (setProxyJ(address)) {
            Log.d("Wallet.java", "setProxy(): success");
            Log.d("Wallet.java", getStatus().errorString);
            return true;
        } else {
            Log.d("Wallet.java", "setProxy(): failure");
            Log.d("Wallet.java", getStatus().errorString);
            return false;
        }
    }
    public long getBalance() {
        return getBalance(accountIndex);
    }

    public native long getBalance(int accountIndex);

    public native long getBalanceAll();

    public long getUnlockedBalance() {
        return getUnlockedBalance(accountIndex);
    }

    public native long getUnlockedBalanceAll();

    public native long getUnlockedBalance(int accountIndex);

    public native boolean isWatchOnly();

    public native long getBlockChainHeight();

    public native long getApproximateBlockChainHeight();

    public native long getDaemonBlockChainHeight();

    public native long getDaemonBlockChainTargetHeight();

    boolean synced = false;

    public boolean isSynchronized() {
        return synced;
    }

    public void setSynchronized() {
        this.synced = true;
    }

    public static native String getDisplayAmount(long amount);

    public static native long getAmountFromString(String amount);

    public static native long getAmountFromDouble(double amount);

    public static native String generatePaymentId();

    public static native boolean isPaymentIdValid(String payment_id);

    public static boolean isAddressValid(String address) {
        return isAddressValid(address, WalletManager.getInstance().getNetworkType().getValue());
    }

    public static native boolean isAddressValid(String address, int networkType);

    public static native String getPaymentIdFromAddress(String address, int networkType);

    public static native long getMaximumAllowedAmount();

    public native void startRefresh();

    public native void pauseRefresh();

    public native boolean startBackgroundSync();

    public native boolean stopBackgroundSync(String password);

    public native boolean refresh();

    public native void refreshAsync();

    public native void rescanBlockchainAsyncJ();

    public void rescanBlockchainAsync() {
        synced = false;
        rescanBlockchainAsyncJ();
    }

//TODO virtual void setAutoRefreshInterval(int millis) = 0;
//TODO virtual int autoRefreshInterval() const = 0;


    private PendingTransaction pendingTransaction = null;

    public PendingTransaction getPendingTransaction() {
        return pendingTransaction;
    }

    public void disposePendingTransaction() {
        if (pendingTransaction != null) {
            disposeTransaction(pendingTransaction);
            pendingTransaction = null;
        }
    }

    public PendingTransaction createTransaction(TxData txData, ArrayList<String> selectedUtxos) throws Exception {
        return createTransaction(
                txData.getDestinationAddress(),
                txData.getAmount(),
                false,
                txData.getMixin(),
                txData.getPriority(),
                selectedUtxos);
    }

    public PendingTransaction createTransaction(String dst_addr,
                                                long amount, boolean sweepAll, int mixin_count,
                                                PendingTransaction.Priority priority,
                                                ArrayList<String> selectedUtxos) throws Exception {
        disposePendingTransaction();
        int _priority = priority.getValue();
        ArrayList<String> preferredInputs;
        if (selectedUtxos.isEmpty()) {
            // no inputs manually selected, we are sending from home screen most likely, or user somehow broke the app
            preferredInputs = selectUtxos(amount, false);
        } else {
            preferredInputs = selectedUtxos;
            checkSelectedAmounts(preferredInputs, amount, false);
        }
        long txHandle =
                (sweepAll ?
                        createSweepTransaction(dst_addr, "", mixin_count, _priority,
                                accountIndex, preferredInputs) :
                        createTransactionJ(dst_addr, "", amount, mixin_count, _priority,
                                accountIndex, preferredInputs));
        pendingTransaction = new PendingTransaction(txHandle);
        return pendingTransaction;
    }


    private void checkSelectedAmounts(List<String> selectedUtxos, long amount, boolean sendAll) throws Exception {
        if (!sendAll) {
            long amountSelected = 0;
            for (CoinsInfo coinsInfo : getUtxos()) {
                if (selectedUtxos.contains(coinsInfo.getKeyImage())) {
                    amountSelected += coinsInfo.getAmount();
                }
            }

            if (amountSelected <= amount) {
                throw new Exception("insufficient wallet balance");
            }
        }
    }

    private native long createTransactionJ(String dst_addr, String payment_id,
                                           long amount, int mixin_count,
                                           int priority, int accountIndex, ArrayList<String> key_images);

    public UnsignedTransaction loadUnsignedTxJ(String inputFile) {
        long unsignedTx = loadUnsignedTx(inputFile);
        return new UnsignedTransaction(unsignedTx);
    }

    public native long loadUnsignedTx(String inputFile);


    private native long createSweepTransaction(String dst_addr, String payment_id,
                                               int mixin_count,
                                               int priority, int accountIndex,  ArrayList<String> key_images);


    public PendingTransaction createSweepUnmixableTransaction() {
        disposePendingTransaction();
        long txHandle = createSweepUnmixableTransactionJ();
        pendingTransaction = new PendingTransaction(txHandle);
        return pendingTransaction;
    }

    private native long createSweepUnmixableTransactionJ();

//virtual UnsignedTransaction * loadUnsignedTx(const std::string &unsigned_filename) = 0;
//virtual bool submitTransaction(const std::string &fileName) = 0;

    public native void disposeTransaction(PendingTransaction pendingTransaction);

//virtual bool exportKeyImages(const std::string &filename) = 0;
//virtual bool importKeyImages(const std::string &filename) = 0;


//virtual TransactionHistory * history() const = 0;

    private TransactionHistory history = null;

    public TransactionHistory getHistory() {
        if (history == null) {
            history = new TransactionHistory(getHistoryJ(), accountIndex);
        }
        return history;
    }

    private native long getHistoryJ();

    public native boolean exportOutputs(String filename, boolean all);
    public native String importKeyImages(String filename);
    public native String submitTransaction(String filename);

    public Coins getCoins() {
        if (coins == null) {
            coins = new Coins(getCoinsJ());
        }
        coins.refresh();
        return coins;
    }

    private native long getCoinsJ();

    public List<CoinsInfo> getUtxos() {
        return getCoins().getAll();
    }

    private long calculateBasicFee(long amount) {
        ArrayList<Pair<String, Long>> destinations = new ArrayList<>();
        destinations.add(new Pair<>("87MRtZPrWUCVUgcFHdsVb5MoZUcLtqfD3FvQVGwftFb8eSdMnE39JhAJcbuSW8X2vRaRsB9RQfuCpFciybJFHaz3QYPhCLw", amount));
        // destination string doesn't actually matter here, so i'm using the donation address. amount also technically doesn't matter
        // priority also isn't accounted for in the Monero C++ code. maybe this is a bug by the core Monero team, or i'm using an outdated method.
        return WalletManager.getInstance().getWallet().estimateTransactionFee(destinations, PendingTransaction.Priority.Priority_Low);
    }

    public long estimateTransactionFee(List<Pair<String, Long>> destinations, PendingTransaction.Priority priority) {
        int _priority = priority.getValue();
        return estimateTransactionFee(destinations, _priority);
    }

    private native long estimateTransactionFee(List<Pair<String, Long>> destinations, int priority);


    public ArrayList<String> selectUtxos(long amount, boolean sendAll) throws Exception {
        final long basicFeeEstimate = calculateBasicFee(amount);
        final long amountWithBasicFee = amount + basicFeeEstimate;
        ArrayList<String> selectedUtxos = new ArrayList<>();
        ArrayList<String> seenTxs = new ArrayList<>();
        List<CoinsInfo> utxos = getUtxos();
        long amountSelected = 0;
        Collections.sort(utxos);
        //loop through each utxo
        for (CoinsInfo coinsInfo : utxos) {
            if (!coinsInfo.isSpent() && coinsInfo.isUnlocked()) { //filter out spent and locked outputs
                if (sendAll) {
                    // if send all, add all utxos and set amount to send all
                    selectedUtxos.add(coinsInfo.getKeyImage());
                    amountSelected = Wallet.SWEEP_ALL;
                } else {
                    //if amount selected is still less than amount needed, and the utxos tx hash hasn't already been seen, add utxo
                    if (amountSelected <= amountWithBasicFee && !seenTxs.contains(coinsInfo.getHash())) {
                        selectedUtxos.add(coinsInfo.getKeyImage());
                        // we don't want to spend multiple utxos from the same transaction, so we prevent that from happening here.
                        seenTxs.add(coinsInfo.getHash());
                        amountSelected += coinsInfo.getAmount();
                    }
                }
            }
        }

        if (amountSelected < amountWithBasicFee && !sendAll) {
            throw new Exception("insufficient wallet balance");
        }

        return selectedUtxos;
    }

    public void refreshHistory() {
        getHistory().refreshWithNotes(this);
    }

    public native String importOutputsJ(String filename);
    public native boolean hasUnknownKeyImages();
    public native long viewOnlyBalance();
    public native boolean exportKeyImages(String filename, boolean all);
    public native String signAndExportJ(String inputFile, String outputFile);
    public native boolean setTrustedDaemon(boolean arg);

    //virtual AddressBook * addressBook() const = 0;
    //virtual void setListener(WalletListener *) = 0;

    private native long setListenerJ(WalletListener listener);

    public void setListener(WalletListener listener) {
        this.listenerHandle = setListenerJ(listener);
    }

    public native int getDefaultMixin();

    public native void setDefaultMixin(int mixin);

    public native boolean setUserNote(String txid, String note);

    public native String getUserNote(String txid);

    public native String getTxKey(String txid);

//virtual std::string signMessage(const std::string &message) = 0;
//virtual bool verifySignedMessage(const std::string &message, const std::string &addres, const std::string &signature) const = 0;

//virtual bool parse_uri(const std::string &uri, std::string &address, std::string &payment_id, uint64_t &tvAmount, std::string &tx_description, std::string &recipient_name, std::vector<std::string> &unknown_parameters, std::string &error) = 0;
//virtual bool rescanSpent() = 0;

    private static final String NEW_ACCOUNT_NAME = "Untitled account"; // src/wallet/wallet2.cpp:941

    public void addAccount() {
        addAccount(NEW_ACCOUNT_NAME);
    }

    public native void addAccount(String label);

    public String getAccountLabel() {
        return getAccountLabel(accountIndex);
    }

    public String getAccountLabel(int accountIndex) {
        String label = getSubaddressLabel(accountIndex, 0);
        if (label.equals(NEW_ACCOUNT_NAME)) {
            String address = getAddress(accountIndex);
            int len = address.length();
            label = address.substring(0, 6) +
                    "\u2026" + address.substring(len - 6, len);
        }
        return label;
    }

    public String getSubaddressLabel(int addressIndex) {
        return getSubaddressLabel(accountIndex, addressIndex);
    }

    public native String getSubaddressLabel(int accountIndex, int addressIndex);

    public void setAccountLabel(String label) {
        setAccountLabel(accountIndex, label);
    }

    public void setAccountLabel(int accountIndex, String label) {
        setSubaddressLabel(accountIndex, 0, label);
    }

    public void setSubaddressLabel(int addressIndex, String label) {
        setSubaddressLabel(accountIndex, addressIndex, label);
        refreshHistory();
    }

    public native void setSubaddressLabel(int accountIndex, int addressIndex, String label);

    public native int getNumAccounts();

    public int getNumSubaddresses() {
        return getNumSubaddresses(accountIndex);
    }

    public native int getNumSubaddresses(int accountIndex);

    public String getNewSubaddress() {
        return getNewSubaddress(accountIndex);
    }

    public String getNewSubaddress(int accountIndex) {
        String timeStamp = new SimpleDateFormat("yyyy-MM-dd-HH:mm:ss", Locale.US).format(new Date());
        addSubaddress(accountIndex, timeStamp);
        String subaddress = getLastSubaddress(accountIndex);
        Timber.d("%d: %s", getNumSubaddresses(accountIndex) - 1, subaddress);
        return subaddress;
    }

    public native void addSubaddress(int accountIndex, String label);

    public String getLastSubaddress(int accountIndex) {
        return getSubaddress(accountIndex, getNumSubaddresses(accountIndex) - 1);
    }

    public Device getDeviceType() {
        int device = getDeviceTypeJ();
        return Device.values()[device + 1]; // mapping is monero+1=android
    }

    private native int getDeviceTypeJ();

}
