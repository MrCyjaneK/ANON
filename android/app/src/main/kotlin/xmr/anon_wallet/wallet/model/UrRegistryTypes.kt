package xmr.anon_wallet.wallet.model


enum class UrRegistryTypes(val type: String, val tag: Int) {
    XMR_OUTPUT("xmr-output", 610),
    XMR_KEY_IMAGE("xmr-keyimage", 611),
    XMR_TX_UNSIGNED("xmr-txunsigned", 612),
    XMR_TX_SIGNED("xmr-txsigned", 613);

    override fun toString(): String {
        return type
    }
    companion object {
        fun fromString(type: String): UrRegistryTypes? {
            return UrRegistryTypes.values().find { it.type == type }
        }
    }
}