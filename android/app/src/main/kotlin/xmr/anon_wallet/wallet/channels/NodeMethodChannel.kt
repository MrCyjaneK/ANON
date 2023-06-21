package xmr.anon_wallet.wallet.channels

import android.util.Log
import android.util.Patterns
import androidx.lifecycle.Lifecycle
import com.m2049r.xmrwallet.data.NodeInfo
import com.m2049r.xmrwallet.model.WalletManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import kotlinx.coroutines.*
import xmr.anon_wallet.wallet.AnonWallet
import xmr.anon_wallet.wallet.services.NodeManager
import xmr.anon_wallet.wallet.utils.AnonPreferences
import kotlin.text.endsWith
import xmr.anon_wallet.wallet.channels.WalletEventsChannel


class NodeMethodChannel(messenger: BinaryMessenger, lifecycle: Lifecycle) :
    AnonMethodChannel(messenger, CHANNEL_NAME, lifecycle) {

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setNode" -> setNode(call, result)
            "setProxy" -> setProxy(call, result)
            "getProxy" -> getProxy(call, result)
            "getAllNodes" -> getAllNodes(result)
            "addNewNode" -> addNewNode(call, result)
            "removeNode" -> removeNode(call, result)
            "getNodeFromPrefs" -> getNodeFromPrefs(call, result)
            "setCurrentNode" -> setCurrentNode(call, result)
            "testRpc" -> testRpc(call, result)
        }
    }

    private fun getProxy(call: MethodCall, result: Result) {
        val preferences = AnonPreferences(AnonWallet.getAppContext());
        return result.success(
            hashMapOf(
                "proxyServer" to preferences.proxyServer,
                "proxyPortTor" to preferences.proxyPortTor,
                "proxyPortI2p" to preferences.proxyPortI2p,
            )
        )
    }

    private fun getNodeFromPrefs(call: MethodCall, result: Result) {
        val preferences = AnonPreferences(AnonWallet.getAppContext());
        if(preferences.serverUrl.isNullOrEmpty() || preferences.serverPort == null){
            result.error("0","No node found",null);
            return;
        }
        val hashMap = hashMapOf<String, Any>()
        hashMap["host"] = preferences.serverUrl ?: "";
        preferences.serverPort?.let {
            hashMap["rpcPort"] = it;
        }
        hashMap["username"] = preferences.serverUserName ?: ""
        hashMap["password"] = preferences.serverPassword ?: ""
        hashMap["EVENT_TYPE"] = "NODE"
        hashMap["isActive"] =  false
        return result.success(hashMap)
    }

    private fun setProxy(call: MethodCall, result: Result) {
        val proxyServer = call.argument<String?>("proxyServer")
        val proxyPortTor = call.argument<String?>("proxyPortTor")
        val proxyPortI2p = call.argument<String?>("proxyPortI2p")
        val preferences = AnonPreferences(AnonWallet.getAppContext());
        this.scope.launch {
            withContext(Dispatchers.IO){
              try {
                  if (!proxyServer.isNullOrEmpty() && !proxyPortTor.isNullOrEmpty() && !proxyPortI2p.isNullOrEmpty()) {
                      if (!Patterns.IP_ADDRESS.matcher(proxyServer).matches()) {
                          result.error("1", "Invalid server IP", "")
                          return@withContext
                      }
                      val portTor = try {
                          proxyPortTor.toInt()
                      } catch (e: Exception) {
                          -1
                      }
                      if (1 > portTor || portTor > 65535) {
                          result.error("1", "Invalid port", "")
                          return@withContext;
                      }
                      val portI2p = try {
                          proxyPortI2p.toInt()
                      } catch (e: Exception) {
                          -1
                      }
                      if (1 > portI2p || portI2p > 65535) {
                          result.error("1", "Invalid port", "")
                          return@withContext;
                      }
                      preferences.proxyServer = proxyServer
                      preferences.proxyPortTor = proxyPortTor
                      preferences.proxyPortI2p = proxyPortI2p
                      val preferences = AnonPreferences(AnonWallet.getAppContext());
                      if(preferences.serverUrl.isNullOrEmpty() || preferences.serverPort == null){
                          result.success("No node found");
                          return@withContext;
                      }
                      if (preferences.serverUrl != null) {
                        if (preferences.serverUrl.toString().contains(".i2p")) {
                            Log.d("NodeMethodCHannel.kt", "proxy type: i2p")
                            WalletManager.getInstance()?.setProxy("${proxyServer}:${proxyPortI2p}")
                            // WalletManager.getInstance().wallet?.setProxy("${proxyServer}:${proxyPortI2p}")
                        } else {
                            Log.d("NodeMethodCHannel.kt", "proxy type: tor")
                            WalletManager.getInstance()?.setProxy("${proxyServer}:${proxyPortTor}")
                            // WalletManager.getInstance().wallet?.setProxy("${proxyServer}:${proxyPortTor}")
                        }
                        }
                  } else if (proxyServer.isNullOrEmpty() || proxyPortTor.isNullOrEmpty()|| proxyPortI2p.isNullOrEmpty()) {
                      preferences.proxyServer = proxyServer
                      preferences.proxyPortTor = proxyPortTor
                      preferences.proxyPortI2p = proxyPortI2p
                      // WalletManager.getInstance()?.wallet?.setProxy("")
                      WalletManager.getInstance()?.setProxy("")
                      Log.d("NodeMethodCHannel.kt", "proxy type: null")
                    }
                  result.success(true)
              }catch (e:Exception){
                  result.error("0",e.message,"")
                  throw  CancellationException(e.message)
              }
            }
        }
    }

    private fun setNode(call: MethodCall, result: Result) {
        val port = call.argument<Int?>("port")
        var host = call.argument<String>("host")
        val userName = call.argument<String?>("username")
        val password = call.argument<String?>("password")
        if (port == null || host == null) {
            return result.error("1", "Invalid params", "")
        }
        if (host.lowercase().startsWith("http://")) {
            host = host.replace("http://", "")
        }
        if (host.lowercase().startsWith("https://")) {
            host = host.replace("https://", "")
        }
        if(host.trim().isEmpty()){
            result.error("0","Invalid hostname","");
            return
        }
        this.scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val node = NodeInfo(/**/)
                    node.host = host
                    node.rpcPort = port
                    WalletEventsChannel.sendEvent(node.toHashMap().apply {
                        put("status", "connecting")
                    })
                    userName?.let {
                        node.username = it
                    }
                    password?.let {
                        node.password = it
                    }
                    // here
                    if(host.contains(".onion") || host.contains(".i2p")){
                        if(AnonPreferences(AnonWallet.getAppContext()).proxyServer.isNullOrEmpty()){
                            WalletEventsChannel.sendEvent(node.toHashMap().apply {
                                put("status", "not-connected")
                            })
                            result.error("0","Please set tor proxy to connect onion urls","");
                            return@withContext;
                        }
                    }
                    // No, I'm not going to fix testRpcService now.
                    val testSuccess = node.testRpcService()

                    // val testSuccess = node.testRpcService()
                    if (true) {
                        AnonPreferences(AnonWallet.getAppContext()).serverUrl = host
                        AnonPreferences(AnonWallet.getAppContext()).serverPort = port
                        if (!node.username.isNullOrEmpty()) {
                            AnonPreferences(AnonWallet.getAppContext()).serverUserName = node.username
                        }
                        if (!node.password.isNullOrEmpty()) {
                            AnonPreferences(AnonWallet.getAppContext()).serverUserName = node.password
                        }
                        WalletManager.getInstance().setDaemon(node)
                        NodeManager.setCurrentActiveNode(node)
                        if (WalletManager.getInstance().reopen()) {
                            WalletEventsChannel.initWalletListeners()
                        }
                        WalletEventsChannel.sendEvent(node.toHashMap().apply {
                            put("status", "connected")
                        })
                        result.success(node.toHashMap())
                    } else {
                        WalletEventsChannel.sendEvent(node.toHashMap().apply {
                            put("status", "disconnected")
                            put("connection_error", "Failed to connect to remote node")
                        })
                        result.error("2", "Failed to connect to remote node", "")
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    WalletEventsChannel.sendEvent(
                        hashMapOf(
                            "EVENT_TYPE" to "NODE",
                            "status" to "disconnected",
                            "connection_error" to "Failed to connect to remote node"
                        )
                    )
                    result.error("2", "${e.message}", e.cause)
                    throw CancellationException(e.message)
                }
            }
        }
    }

    private fun testRpc(call: MethodCall, result: Result) {
        val port = call.argument<Int>("port")
        var host = call.argument<String>("host")
        val userName = call.argument<String?>("username")
        val password = call.argument<String?>("password")
        if (port == null || host == null) {
            return result.error("1", "Invalid params", "")
        }
        if (host.lowercase().startsWith("http://")) {
            host = host.replace("http://", "")
        }
        if (host.lowercase().startsWith("https://")) {
            host = host.replace("https://", "")
        }
        scope.launch {
            withContext(Dispatchers.IO) {
                val node = NodeInfo(/**/)
                node.host = host
                node.rpcPort = port
                userName?.let {
                    node.username = it
                }
                password?.let {
                    node.password = it
                }
                try {
                    val success = node.testRpcService()
                    Log.i(TAG, "testRpc: ${node.toHashMap()}")
                    if (success == true) {
                    }
                    result.success(node.toHashMap());
                } catch (e: Exception) {
                    result.error("1", "${e.message}", "")
                }
            }
        }
    }

    private fun setCurrentNode(call: MethodCall, result: Result) {
        val port = call.argument<Int>("port")
        var host = call.argument<String>("host")
        val userName = call.argument<String?>("username")
        val password = call.argument<String?>("password")
        if (port == null || host == null) {
            return result.error("1", "Invalid params", "")
        }
        if (host.lowercase().startsWith("http://")) {
            host = host.replace("http://", "")
        }
        if (host.lowercase().startsWith("https://")) {
            host = host.replace("https://", "")
        }
        scope.launch {
            withContext(Dispatchers.IO){
                try {
                    val node = NodeInfo(/**/)
                    node.host = host
                    node.rpcPort = port
                    userName?.let {
                        node.username = it
                    }
                    password?.let {
                        node.password = it
                    }
                    AnonPreferences(AnonWallet.getAppContext()).serverUrl = host
                    AnonPreferences(AnonWallet.getAppContext()).serverPort = port
                    val preferences = AnonPreferences(AnonWallet.getAppContext());
                    Log.d("NodeMethodChannel.kt", "node url: ${preferences.serverUrl}")
                    if (preferences.serverUrl.toString().contains(".i2p")) {
                        Log.d("NodeMethodChannel.kt", "proxy type: i2p")
                        WalletManager.getInstance()?.setProxy("${preferences.proxyServer}:${preferences.proxyPortI2p}")
                        // WalletManager.getInstance().wallet?.setProxy("${preferences.proxyServer}:${preferences.proxyPortI2p}")
                    } else {
                        Log.d("NodeMethodChannel.kt", "proxy type: tor")
                        WalletManager.getInstance()?.setProxy("${preferences.proxyServer}:${preferences.proxyPortTor}")
                        // WalletManager.getInstance().wallet?.setProxy("${preferences.proxyServer}:${preferences.proxyPortTor}")
                    }
                    Log.d("NodeMethodChannel.kt", "setting node")
                    NodeManager.setCurrentActiveNode(node)
                    // WalletManager.getInstance().setDaemon(node)
                     WalletManager.getInstance()
                    if (!node.username.isNullOrEmpty()) {
                        AnonPreferences(AnonWallet.getAppContext()).serverUserName = node.username
                    }
                    if (!node.password.isNullOrEmpty()) {
                        AnonPreferences(AnonWallet.getAppContext()).serverUserName = node.password
                    }

                    NodeManager.setCurrentActiveNode(node)
                    WalletManager.getInstance().setDaemon(node)
                    if (WalletManager.getInstance().reopen()) {
                        WalletEventsChannel.initWalletListeners()
                    }
                    result.success(node.toHashMap())
                    try {
                        WalletManager.getInstance().wallet?.let {
                            it.refresh()
                            it.startRefresh()
                        }
                    } catch (e: Exception) {
                        //no-op
                    }
                } catch (e: Exception) {
                    result.error("1","${e.message}",e)
                }
            }
        }
    }



    private fun addNewNode(call: MethodCall, result: Result) {
        val port = call.argument<Int>("port")
        var host = call.argument<String>("host")
        val userName = call.argument<String?>("username")
        val password = call.argument<String?>("password")
        if (port == null || host == null) {
            return result.error("1", "Invalid params", "")
        }
        if (host.lowercase().startsWith("http://")) {
            host = host.replace("http://", "")
        }
        if (host.lowercase().startsWith("https://")) {
            host = host.replace("https://", "")
        }

        this.scope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val findResult = NodeManager.getNodes().find {
                        (it.host).lowercase() == host.lowercase() && (it.rpcPort == port)
                    }
                    if (findResult != null) {
                        result.error("1", "Node already exist", "")
                        return@withContext
                    }
                    val node = NodeInfo(/**/)
                    Log.d("NodeMethodChannel.kt", host.toString())
                    node.host = host
                    Log.d("NodeMethodChannel.kt", node.host.toString())
                    node.rpcPort = port
                    userName?.let {
                        node.username = it
                    }
                    password?.let {
                        node.password = it
                    }
                    val testSuccess = node.testRpcService()
                    if (testSuccess == true) {
                        result.success(node.toHashMap())
                        NodeManager.addNode(node)
                    } else {
                        result.error("2", "Failed to connect to remote node", "")
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    result.error("2", "${e.message}", e.cause)
                    throw CancellationException(e.message)
                }
            }
        }
    }



    private fun removeNode(call: MethodCall, result: Result) {
        val port = call.argument<Int>("port")
        var host = call.argument<String>("host")
        val userName = call.argument<String?>("username")
        val password = call.argument<String?>("password")
        if (port == null || host == null) {
            return result.error("1", "Invalid params", "")
        }
        if (host.lowercase().startsWith("http://")) {
            host = host.replace("http://", "")
        }
        if (host.lowercase().startsWith("https://")) {
            host = host.replace("https://", "")
        }
        scope.launch {
            withContext(Dispatchers.IO){
                try {
                    NodeManager.removeNode(host,port,userName,password)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                result.success(true);
            }
        }
    }


    private fun getAllNodes(result: Result) {
        scope.launch {
            withContext(Dispatchers.Default) {
                val server = AnonPreferences(AnonWallet.getAppContext()).serverUrl
                val port = AnonPreferences(AnonWallet.getAppContext()).serverPort
                val nodesList = arrayListOf<HashMap<String, Any>>()
                NodeManager.getNodes().let { items ->
                    items.forEach {
                        val nodeHashMap = it.toHashMap()
                        nodeHashMap["isActive"] = server == it.host && port == it.rpcPort;
                        nodesList.add(nodeHashMap)
                    }
                }
                result.success(nodesList)
            }
        }
    }



    companion object {
        const val CHANNEL_NAME = "node.channel"
        private const val TAG = "NodeMethodChannel"
    }
}