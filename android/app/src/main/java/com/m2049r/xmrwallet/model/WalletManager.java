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

import com.m2049r.xmrwallet.data.Node;
import com.m2049r.xmrwallet.utils.RestoreHeight;

import org.jetbrains.annotations.NotNull;

import java.io.File;
import java.io.FilenameFilter;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import kotlin.Unit;
import kotlin.jvm.functions.Function0;
import lombok.Getter;
import timber.log.Timber;
import xmr.anon_wallet.wallet.AnonWallet;
import android.util.Log;

public class WalletManager {

    static {
        System.loadLibrary("monerujo");
    }

    // no need to keep a reference to the REAL WalletManager (we get it every tvTime we need it)
    private static WalletManager Instance = null;

    public static synchronized WalletManager getInstance() {
        if (WalletManager.Instance == null) {
            WalletManager.Instance = new WalletManager();
        }

        return WalletManager.Instance;
    }

    private Function0<Unit> onManageCallback;

    public void onManageCallBack(@NotNull Function0<Unit> function) {
        this.onManageCallback = function;
    }

    public String addressPrefix() {
        return addressPrefix(getNetworkType());
    }

    static public String addressPrefix(NetworkType networkType) {
        switch (networkType) {
            case NetworkType_Testnet:
                return "9A-";
            case NetworkType_Mainnet:
                return "4-";
            case NetworkType_Stagenet:
                return "5-";
            default:
                throw new IllegalStateException("Unsupported Network: " + networkType);
        }
    }

    private Wallet managedWallet = null;

    public Wallet getWallet() {
        return managedWallet;
    }

    private void manageWallet(Wallet wallet) {
        Log.d("WalletManager.java", "manageWallet(): Managing: " + wallet.getName());
        boolean closeAfter = (managedWallet != null);
        Wallet oldWallet = managedWallet;
        managedWallet = wallet;
        if (closeAfter) {
            Log.d("WalletManager.java", "manageWallet(): Closing old wallet: " + oldWallet.getName());
            Runnable r = new Runnable() {
                public void run() {
                    Log.d("WalletManager.java", "[T]: manageWallet(): close start");
                    closeJ(oldWallet);
                    Log.d("WalletManager.java", "[T]: manageWallet(): close end");
                }
            };

            new Thread(r).start();
        }
        if (onManageCallback != null) {
            Log.d("WalletManager.java", "manageWallet(): onManageCallback.invoke()");
            onManageCallback.invoke();
        }
        Log.d("WalletManager.java", "manageWallet(): end");
    }

    private void unmanageWallet(Wallet wallet) {
        if (wallet == null) {
            throw new IllegalArgumentException("Cannot unmanage null!");
        }
        if (getWallet() == null) {
            throw new IllegalStateException("No wallet under management!");
        }
        if (getWallet() != wallet) {
            throw new IllegalStateException(wallet.getName() + " not under management!");
        }
        Timber.d("Unmanaging %s", managedWallet.getName());
        managedWallet = null;
    }

    public Wallet createWallet(File aFile, String password, String seed_offset, String language, long height) {
        long walletHandle = createWalletJ(aFile.getAbsolutePath(), password, seed_offset, language, getNetworkType().getValue());
        Wallet wallet = new Wallet(walletHandle);
        wallet.init(0, proxy);
        manageWallet(wallet);
        // check if online
        Log.d("WalletManager.java", "wallet.getStatus().isOk()");
        if (wallet.getStatus().isOk()) {
            Log.d("WalletManager.java", "wallet.getStatus().isOk(): true");
            wallet.setPassword(password); // this rewrites the keys file (which contains the restore height)
        } else { 
            Timber.e(wallet.getStatus().toString());
        }

        return wallet;
    }

    private native long createWalletJ(String path, String password, String seed_offset, String language, int networkType);

    public Wallet openAccount(String path, int accountIndex, String password) {
        Log.d("WalletManager.java", "openAccount(" + path + ", accountIndex, '****')");
        long walletHandle = openWalletJ(path, password, getNetworkType().getValue());
        Wallet wallet = new Wallet(walletHandle, accountIndex);
        manageWallet(wallet);
        return wallet;
    }

    private String knownPath = "";
    private String knownPassword = "";

    public String proxy = "";

    public Wallet openWallet(String path, String password, boolean shouldManage) {
        Log.d("WalletManager.java", "openWallet(" + path + ", '****'): [" + proxy + "]");
        if (path != "") { 
            knownPath = path;
            knownPassword = password;
        } else {
            Log.d("WalletManager.java", "openWallet(): *not* updating knownPath, knownPassword - given path is \"\"");
        }
        long walletHandle = openWalletJ(path, password, getNetworkType().getValue());
        Wallet wallet = new Wallet(walletHandle);
        wallet.init(0, proxy);

        if (shouldManage) {
            manageWallet(wallet);
        }
        return wallet;
    }

    private native long openWalletJ(String path, String password, int networkType);

    public Wallet recoveryWallet(File aFile, String password,
                                 String mnemonic, String offset,
                                 long restoreHeight) {
        long walletHandle = recoveryWalletJ(aFile.getAbsolutePath(), password,
                mnemonic, offset,
                getNetworkType().getValue(), restoreHeight);
        Wallet wallet = new Wallet(walletHandle);
        manageWallet(wallet);
        return wallet;
    }

    private native long recoveryWalletJ(String path, String password,
                                        String mnemonic, String offset,
                                        int networkType, long restoreHeight);

    public Wallet recoveryWalletPolyseed(File aFile, String password,
                                 String mnemonic, String offset) {
        long walletHandle = recoveryWalletPolyseedJ(aFile.getAbsolutePath(), password,
                mnemonic, offset,
                getNetworkType().getValue());
        Wallet wallet = new Wallet(walletHandle);
        manageWallet(wallet);
        return wallet;
    }

    private native long recoveryWalletPolyseedJ(String path, String password,
                                        String mnemonic, String offset,
                                        int networkType);

    public Wallet createWalletWithKeys(File aFile, String password, String language, long restoreHeight,
                                       String addressString, String viewKeyString, String spendKeyString) {
        long walletHandle = createWalletFromKeysJ(aFile.getAbsolutePath(), password,
                language, getNetworkType().getValue(), restoreHeight,
                addressString, viewKeyString, spendKeyString);
        Wallet wallet = new Wallet(walletHandle);
        manageWallet(wallet);
        return wallet;
    }

    private native long createWalletFromKeysJ(String path, String password,
                                              String language,
                                              int networkType,
                                              long restoreHeight,
                                              String addressString,
                                              String viewKeyString,
                                              String spendKeyString);

    public Wallet createWalletFromDevice(File aFile, String password, long restoreHeight,
                                         String deviceName) {
        long walletHandle = createWalletFromDeviceJ(aFile.getAbsolutePath(), password,
                getNetworkType().getValue(), deviceName, restoreHeight,
                "5:20");
        Wallet wallet = new Wallet(walletHandle);
        manageWallet(wallet);
        return wallet;
    }

    private native long createWalletFromDeviceJ(String path, String password,
                                                int networkType,
                                                String deviceName,
                                                long restoreHeight,
                                                String subaddressLookahead);


    public native boolean closeJ(Wallet wallet);

    public boolean reopen() {
        Log.d("WalletManager.java", "reopen()");
        if (knownPath == "") {
            return false;
        }
        Wallet wallet = openWallet(knownPath, knownPassword, false);
        // NOTE: Closing logic moved to manageWallet.
        // if (managedWallet != null) {
        //     close(managedWallet);
        // } else {
        //     Log.d("WalletManager.java", "reopen(): we are not going to close() a null managedWallet");
        // }
        manageWallet(wallet);
        // openWallet(knownPath, knownPassword);
        return true;
    }

    public boolean close(Wallet wallet) {
        Log.d("WalletManager.java", "close()");
        unmanageWallet(wallet);
        boolean closed = closeJ(wallet);
        if (!closed) {
            // in case we could not close it
            // we manage it again
            Log.d("WalletManager.java", "close(): failed to close");
            manageWallet(wallet);
        } else {
            Log.d("WalletManager.java", "close(): success");
        }
        return closed;
    }

    public boolean walletExists(File aFile) {
        return walletExists(aFile.getAbsolutePath());
    }

    public native boolean walletExists(String path);

    public native boolean verifyWalletPassword(String keys_file_name, String password, boolean watch_only);

    public boolean verifyWalletPasswordOnly(String keys_file_name, String password) {
        return queryWalletDeviceJ(keys_file_name, password) >= 0;
    }

    public Wallet.Device queryWalletDevice(String keys_file_name, String password) {
        int device = queryWalletDeviceJ(keys_file_name, password);
        return Wallet.Device.values()[device + 1]; // mapping is monero+1=android
    }

    private native int queryWalletDeviceJ(String keys_file_name, String password);

    //public native List<String> findWallets(String path); // this does not work - some error in boost

    public class WalletInfo implements Comparable<WalletInfo> {
        @Getter
        final private File path;
        @Getter
        final private String name;

        public WalletInfo(File wallet) {
            path = wallet.getParentFile();
            name = wallet.getName();
        }

        @Override
        public int compareTo(WalletInfo another) {
            return name.toLowerCase().compareTo(another.name.toLowerCase());
        }
    }

    public List<WalletInfo> findWallets(File path) {
        List<WalletInfo> wallets = new ArrayList<>();
        Timber.d("Scanning: %s", path.getAbsolutePath());
        File[] found = path.listFiles(new FilenameFilter() {
            public boolean accept(File dir, String filename) {
                return filename.endsWith(".keys");
            }
        });
        for (int i = 0; i < found.length; i++) {
            String filename = found[i].getName();
            File f = new File(found[i].getParent(), filename.substring(0, filename.length() - 5)); // 5 is length of ".keys"+1
            wallets.add(new WalletInfo(f));
        }
        return wallets;
    }

//TODO virtual bool checkPayment(const std::string &address, const std::string &txid, const std::string &txkey, const std::string &daemon_address, uint64_t &received, uint64_t &height, std::string &error) const = 0;

    private String daemonAddress = null;
    private final NetworkType networkType = AnonWallet.INSTANCE.getNetworkType();

    public NetworkType getNetworkType() {
        return networkType;
    }

    // this should not be called on the main thread as it connects to the node (and takes a long time)
    public void setDaemon(Node node) {
        if (node != null) {
            this.daemonAddress = node.getAddress();
            if (networkType != node.getNetworkType())
                throw new IllegalArgumentException("network type does not match");
            this.daemonUsername = node.getUsername();
            this.daemonPassword = node.getPassword();
            setDaemonAddressJ(daemonAddress);
        } else {
            this.daemonAddress = null;
            this.daemonUsername = "";
            this.daemonPassword = "";
            //setDaemonAddressJ(""); // don't disconnect as monero code blocks for many seconds!
            //TODO: need to do something about that later
        }
    }

    public String getDaemonAddress() {
        return this.daemonAddress;
    }

    private native void setDaemonAddressJ(String address);

    private String daemonUsername = "";

    public String getDaemonUsername() {
        return daemonUsername;
    }

    private String daemonPassword = "";

    public String getDaemonPassword() {
        return daemonPassword;
    }

    public native int getDaemonVersion();

    public native long getBlockchainHeight();

    public native long getBlockchainTargetHeight();

    public native long getNetworkDifficulty();

    public native double getMiningHashRate();

    public native long getBlockTarget();

    public native boolean isMining();

    public native boolean startMining(String address, boolean background_mining, boolean ignore_battery);

    public native boolean stopMining();

    public native String resolveOpenAlias(String address, boolean dnssec_valid);

    public native boolean setProxyJ(String address);

    public boolean setProxy(String address) {
        Log.d("WalletManager.java", "setProxy("+address+")");
        proxy = address;
        if (setProxyJ(address)) {
            Log.d("WalletManager.java", "setProxy(): success");
            Log.d("WalletManager.java", "no logging here, yet.");
            return true;
        } else {
            Log.d("WalletManager.java", "setProxy(): failure");
            Log.d("WalletManager.java", "no logging here, yet.");
            return true;
        }
    }
//TODO static std::tuple<bool, std::string, std::string, std::string, std::string> checkUpdates(const std::string &software, const std::string &subdir);

    static public native void initLogger(String argv0, String defaultLogBaseName);

    //TODO: maybe put these in an enum like in monero core - but why?
    static public int LOGLEVEL_SILENT = -1;
    static public int LOGLEVEL_WARN = 0;
    static public int LOGLEVEL_INFO = 1;
    static public int LOGLEVEL_DEBUG = 2;
    static public int LOGLEVEL_TRACE = 3;
    static public int LOGLEVEL_MAX = 4;

    static public native void setLogLevel(int level);

    static public native void logDebug(String category, String message);

    static public native void logInfo(String category, String message);

    static public native void logWarning(String category, String message);

    static public native void logError(String category, String message);

    static public native String moneroVersion();
}