package xmr.anon_wallet.wallet.services

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.m2049r.xmrwallet.data.NodeInfo
import com.m2049r.xmrwallet.model.WalletManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import xmr.anon_wallet.wallet.AnonWallet
import xmr.anon_wallet.wallet.channels.WalletEventsChannel
import xmr.anon_wallet.wallet.utils.AnonPreferences
import android.util.Log;

object NodeManager {

    private var isConfigured = false
    private var currentNode: NodeInfo? = null
    private var nodes = arrayListOf<NodeInfo>()
    private val gson = Gson()

    fun isNodeConfigured(): Boolean {
        return isConfigured
    }

    suspend fun setNode() {
        Log.d("NodeManager.kt", "setNode()")
        withContext(Dispatchers.IO) {
            val preferences = AnonPreferences(AnonWallet.getAppContext())
            val serverUrl = preferences.serverUrl
            val serverPort = preferences.serverPort
            Log.d("NodeManager.kt", "setNode(): " + preferences.serverUrl + ":" + preferences.serverPort)
            if (serverUrl == null || serverUrl.isEmpty() || serverPort == null) {
                isConfigured = false
                WalletEventsChannel.sendEvent(
                    hashMapOf(
                        "EVENT_TYPE" to "NODE",
                        "status" to "disconnected",
                        "connection_error" to ""
                    )
                )
                return@withContext
            }
            try {
                val node = NodeInfo(/**/)
                node.host = serverUrl
                node.rpcPort = serverPort
                preferences.serverUserName?.let { username ->
                    preferences.serverPassword?.let {
                        node.username = username
                        node.password = it
                    }
                }
                WalletEventsChannel.sendEvent(node.toHashMap().apply {
                    put("status", "connecting")
                })
                currentNode = node
                if (node.host.contains(".i2p")) {
                    WalletManager.getInstance().setProxy(getProxyI2p())
                } else {
                    WalletManager.getInstance().setProxy(getProxyTor())
                }
                WalletManager.getInstance().setDaemon(node)
                val usedProxy = if (node.host.contains(".i2p")) {
                    getProxyI2p()
                } else {
                    getProxyTor()
                }
                Log.d("NodeManager.kt", "usedProxy:" + usedProxy)
                if (WalletManager.getInstance().reopen()) {
                    WalletEventsChannel.initWalletListeners()
                }
                isConfigured = true
                WalletEventsChannel.sendEvent(node.toHashMap().apply {
                    put("status", "connected")
                })
            } catch (e: Exception) {
                WalletEventsChannel.sendEvent(
                    hashMapOf(
                        "EVENT_TYPE" to "NODE",
                        "status" to "disconnected",
                        "connection_error" to "Error ${e.message}"
                    )
                )
                e.printStackTrace()
            }
        }
    }

    fun getNode(): NodeInfo? {
        return currentNode
    }

    fun setCurrentActiveNode(node: NodeInfo) {
        Log.d("NodeManager.kt", "setCurrenctActiveNode(node.host: "+node.host+")")
        currentNode = node
    }

    suspend fun testRPC(): Boolean {
        return withContext(Dispatchers.IO) {
            if (currentNode != null) {
                try {
                    if (currentNode!!.testRpcService() == true) {
                        val node = currentNode!!.toHashMap()
                        node["status"] = "connected"
                        node["connection_error"] = ""
                        WalletEventsChannel.sendEvent(node)
                        return@withContext true
                    } else {
                        val node = currentNode!!.toHashMap()
                        node["status"] = "disconnected"
                        node["connection_error"] = "Unable to reach node"
                        WalletEventsChannel.sendEvent(node)
                        return@withContext false
                    }
                } catch (e: Exception) {
                    val node = currentNode!!.toHashMap()
                    node["status"] = "disconnected"
                    node["connection_error"] = "$e"
                    WalletEventsChannel.sendEvent(node)
                    return@withContext false
                }
            } else {
                hashMapOf(
                    "EVENT_TYPE" to "NODE",
                    "status" to "disconnected",
                    "connection_error" to "Node not connected"
                )
                return@withContext false
            }
        }
    }


    suspend fun storeNodesList() {
        withContext(Dispatchers.IO) {
            val nodeListFile = AnonWallet.nodesFile
            if (!nodeListFile.exists()) {
                nodeListFile.createNewFile()
            }
            val jsonObj: List<JSONObject> = nodes.map { JSONObject(it.toHashMap().toMap()) }
            nodeListFile.writeText(JSONArray(jsonObj).toString())
        }
    }

    private suspend fun readNodes() {
        nodes = arrayListOf()
        withContext(Dispatchers.IO) {
            val nodeListFile = AnonWallet.nodesFile
            if (!nodeListFile.exists()) {
                nodeListFile.createNewFile()
            }
            val values = nodeListFile.readText()
            if (values.isNotEmpty()) {
                val jsonArray = JSONArray(values)
                nodes = arrayListOf();
                repeat(jsonArray.length()) {
                    val item = jsonArray.getJSONObject(it)
                    val nodeItem: NodeInfo = gson.fromJson(item.toString(), object : TypeToken<NodeInfo>() {}.type)
                    nodes.add(nodeItem)
                }
            } else {
                nodes = arrayListOf();
            }
        }
    }

    private fun getProxyTor(): String {
        val prefs = AnonPreferences(AnonWallet.getAppContext());
        return if (prefs.proxyPortTor.isNullOrEmpty() || prefs.proxyServer.isNullOrEmpty()) {
            ""
        } else {
            "${prefs.proxyServer}:${prefs.proxyPortTor}"
        }
    }

    private fun getProxyI2p(): String {
        val prefs = AnonPreferences(AnonWallet.getAppContext());
        return if (prefs.proxyPortI2p.isNullOrEmpty() || prefs.proxyServer.isNullOrEmpty()) {
            ""
        } else {
            "${prefs.proxyServer}:${prefs.proxyPortI2p}"
        }
    }

    suspend fun getNodes(): ArrayList<NodeInfo> {
        val allNodes = arrayListOf<NodeInfo?>()
        return withContext(Dispatchers.IO) {
            try {
                readNodes()
                allNodes.addAll(nodes)
                //push if connected node is not in the list or update if it is in the list
                allNodes.filterNotNull().find { it.host == currentNode?.host && it.rpcPort == currentNode?.rpcPort }
                    .let {
                        if (it == null && currentNode != null) {
                            allNodes.add(currentNode!!)
                        }
                    }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            return@withContext ArrayList(allNodes.filterNotNull().distinctBy { it.toString() })
        }
    }

    suspend fun addNode(node: NodeInfo) {
        readNodes() // it can't hurt.
        nodes.add(node)
        storeNodesList()
    }

    suspend fun updateExistingNode(node: NodeInfo) {
        val newList = arrayListOf<NodeInfo>()
        nodes.forEach {
            if (node.host == it.host && node.rpcPort == it.rpcPort) {
                newList.add(node)
            } else {
                newList.add(it)
            }
        }
        nodes = newList
        storeNodesList()
    }

    suspend fun removeNode(host: String, port: Int, userName: String?, password: String?) {
        nodes.removeIf {
            it.host == host &&
                    it.rpcPort == port
        }
        storeNodesList()
    }

}
