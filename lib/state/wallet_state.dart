import 'package:anon_wallet/channel/wallet_events_channel.dart';
import 'package:anon_wallet/models/sub_address.dart';
import 'package:anon_wallet/models/transaction.dart';
import 'package:anon_wallet/models/wallet.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final walletStateStreamProvider =
    StreamProvider<Wallet?>((ref) => WalletEventsChannel().walletStream());
final walletLoadingStreamProvider =
    StreamProvider<bool>((ref) => WalletEventsChannel().walletOpenStream());

final walletLoadingProvider =
    Provider<bool?>((ref) => ref.watch(walletLoadingStreamProvider).value);

final walletAddressProvider = Provider((ref) {
  var walletAsync = ref.watch(walletStateStreamProvider);
  Wallet? wallet = walletAsync.value;
  return wallet != null ? wallet.address : "";
});

final walletNodeDaemonHeight = Provider<int>((ref) {
  var walletAsync = ref.watch(walletStateStreamProvider);
  Wallet? wallet = walletAsync.value;
  return wallet != null ? wallet.blockChainHeight.toInt() : 0;
});

final connectionStatus = Provider<bool>((ref) {
  var walletAsync = ref.watch(walletStateStreamProvider);
  Wallet? wallet = walletAsync.value;
  return wallet != null ? wallet.isConnected() : false;
});

final currentSubAddressProvider = Provider<SubAddress?>((ref) {
  var walletAsync = ref.watch(walletStateStreamProvider);
  Wallet? wallet = walletAsync.value;
  return wallet?.currentAddress;
});

final walletTransactions = Provider<List<Transaction>>((ref) {
  var walletAsync = ref.watch(walletStateStreamProvider);
  Wallet? wallet = walletAsync.value;
  if (wallet != null) {
    return wallet.transactions;
  }
  return [];
});

final getSpecificTransaction =
    Provider.family<Transaction, Transaction>((ref, selectedTx) {
  var walletAsync = ref.watch(walletStateStreamProvider);
  Wallet? wallet = walletAsync.value;
  if (wallet != null) {
    try {
      Transaction transaction = wallet.transactions
          .firstWhere((element) => element.hash == selectedTx.hash);
      return transaction;
    } catch (e) {
      return selectedTx;
    }
  }
  return selectedTx;
});

final walletBalanceProvider = Provider((ref) {
  var walletAsync = ref.watch(walletStateStreamProvider);
  Wallet? wallet = walletAsync.value;
  if (wallet == null) {
    return 0;
  } else {
    return wallet.balance;
  }
});

final walletAvailableBalanceProvider = Provider((ref) {
  var walletAsync = ref.watch(walletStateStreamProvider);
  Wallet? wallet = walletAsync.value;
  if (wallet == null) {
    return 0;
  } else {
    return wallet.unlockedBalance;
  }
});
