import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:anon_wallet/anon_wallet.dart';
import 'package:anon_wallet/channel/node_channel.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/channel/wallet_events_channel.dart';
import 'package:anon_wallet/models/wallet.dart';
import 'package:anon_wallet/screens/home/spend/anon_progress.dart';
import 'package:anon_wallet/screens/home/spend/spend_progress_widget.dart';
import 'package:anon_wallet/screens/home/spend/spend_review.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:anon_wallet/screens/landing_screen.dart';
import 'package:anon_wallet/screens/set_pin_screen.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/utils/json_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

void main() async {
  // I kinda lose logs at the beginning..
  if (kDebugMode) {
    await Future.delayed(const Duration(seconds: 3));
  }
  runApp(const SplashScreen());
  WalletState state = await WalletChannel().getWalletState();
  unawaited(showServiceNotification());
  runApp(AnonApp(state));
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeProvider().getTheme(),
      home: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class AnonApp extends StatefulWidget {
  final WalletState state;

  const AnonApp(this.state, {Key? key}) : super(key: key);

  @override
  State<AnonApp> createState() => _AnonAppState();
}

class _AnonAppState extends State<AnonApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'anon',
        onGenerateRoute: (settings) {
          if (settings.name == "/review") {
            return MaterialPageRoute(
                builder: (context) => const AnonSpendReview());
          }
          if (settings.name == "/loading-tx-construct") {
            return MaterialPageRoute(
                builder: (context) => const CircleProgressWidget(
                      progressMessage: "CONSTRUCTING TRANSACTION...",
                    ));
          }
          if (settings.name == "/loading-broadcast-tx") {
            return MaterialPageRoute(
                builder: (context) => const CircleProgressWidget(
                      progressMessage: "SENDING TRANSACTION...",
                    ));
          }
          if (settings.name == "/loading-tx-signing") {
            return MaterialPageRoute(
                builder: (context) => const CircleProgressWidget(
                      progressMessage: "SIGNING TRANSACTION...",
                    ));
          }
          if (settings.name == "/loading-tx") {
            return MaterialPageRoute(
                builder: (context) => const CircleProgressWidget(
                      progressMessage: "LOADING TRANSACTION...",
                    ));
          }
          if (settings.name == "/tx-success") {
            return MaterialPageRoute(
                builder: (context) => const SpendSuccessWidget());
          }
          return null;
        },
        theme: ThemeProvider().getTheme(),
        home: AppMain(widget.state),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WalletEventsChannel();
  }
}

class AppMain extends ConsumerWidget {
  final WalletState state;

  const AppMain(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    return state == WalletState.walletReady
        ? const LockScreen()
        : const LandingScreen();
  }
}

class LockScreen extends HookWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final error = useState<String?>(null);
    final loading = useState<bool>(false);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: loading.value ? const LinearProgressIndicator() : null,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Hero(
            tag: "anon_logo",
            child: SizedBox(
                width: 180, child: Image.asset("assets/anon_logo.png")),
          ),
          const Text("Please enter your pin"),
          const Padding(padding: EdgeInsets.symmetric(vertical: 6)),
          AnimatedOpacity(
            opacity: error.value == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: Text(
              error.value ?? "",
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.red),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
          Expanded(
            child: Container(
              alignment: Alignment.bottomCenter,
              child: Consumer(
                builder: (context, ref, c) {
                  return NumberPadWidget(
                    maxPinSize: maxPinSize,
                    onKeyPress: (s) {
                      error.value = null;
                    },
                    minPinSize: minPinSize,
                    onSubmit: (String pin) {
                      onSubmit(pin, context, ref, error, loading);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onSubmit(String pin, BuildContext context, WidgetRef ref,
      ValueNotifier<String?> error, ValueNotifier<bool> loading) async {
    try {
      error.value = null;
      loading.value = true;
      var proxy = await NodeChannel().getProxy();
      await NodeChannel()
          .setProxy(proxy.serverUrl, proxy.portTor, proxy.portI2p);
      Wallet? wallet = await WalletChannel().openWallet(pin);
      WalletChannel().startSync();
      WalletEventsChannel().initEventChannel();
      loading.value = false;
      if (wallet != null) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (c) => const WalletHome(),
                settings: const RouteSettings(name: "/")),
            (route) => false);
      }
    } on PlatformException catch (e) {
      error.value = e.message;
    } catch (e) {
      print(e);
    } finally {
      loading.value = false;
    }
  }
}

const notificationId = 777;

Future<void> showServiceNotification() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'anon_foreground',
    'Anon Foreground Notification',
    description: 'This channel is used for foreground notification.',
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('anon_mono'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: true,

      notificationChannelId: 'anon_foreground',
      initialNotificationTitle: 'Anon',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.stopSelf();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
        /// the notification id must be equals with AndroidConfiguration when you call configure() method.
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'Anon is running',
          '${DateTime.now()}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'anon_foreground',
              'Anon Foreground Notification',
              icon: 'anon_mono',
              ongoing: true,
              playSound: false,
              enableVibration: false,
            ),
          ),
        );
        final stats = await getStats();
        // if you don't using custom notification, uncomment this
        service.setForegroundNotificationInfo(
          title: "Anon Service",
          content: "Heartbeat at ${stats["updated"]} | ${stats["debug"]}",
        );
      }
    }
  });
}
