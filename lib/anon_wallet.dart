//START WALLET num-pad consts
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/models/config.dart';

const maxPinSize = 12;
const minPinSize = 5;
//END WALLET num-pad consts

//START WALLET tx
const maxConfirms = 10;
//END WALLET tx

bool isViewOnly = anonConfigState.isViewOnly;
bool isAirgapEnabled = false;

WalletState walletState = WalletState.walletNotInitialized;
