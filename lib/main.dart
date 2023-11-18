import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:anon_wallet/anon_wallet.dart';
import 'package:anon_wallet/channel/node_channel.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/channel/wallet_events_channel.dart';
import 'package:anon_wallet/models/wallet.dart';
import 'package:anon_wallet/screens/home/spend/anon_progress.dart';
import 'package:anon_wallet/screens/home/spend/spend_progress_widget.dart';
import 'package:anon_wallet/screens/home/spend/spend_review.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:anon_wallet/screens/home/wallet_lock.dart';
import 'package:anon_wallet/screens/landing_screen.dart';
import 'package:anon_wallet/screens/set_pin_screen.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/utils/json_state.dart';
import 'package:anon_wallet/utils/viewonly_cachepin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  // I kinda lose logs at the beginning..
  if (kDebugMode) {
    await Future.delayed(const Duration(seconds: 3));
  }
  runApp(const SplashScreen());
  WalletState state = await WalletChannel().getWalletState();
  await Permission.notification.request();
  await showServiceNotification();
  runApp(AnonApp(state));
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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

  const AnonApp(this.state, {super.key});

  @override
  State<AnonApp> createState() => _AnonAppState();
}

class _AnonAppState extends State<AnonApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => resetAutolock(),
      child: ProviderScope(
        child: MaterialApp(
          title: 'anon',
          navigatorKey: navigatorKey,
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

  const AppMain(this.state, {super.key});

  @override
  Widget build(BuildContext context, ref) {
    return state == WalletState.walletReady
        ? const LockScreen()
        : const LandingScreen();
  }
}

enum AfterSelectAction {
  actionReceive,
  actionSend,
  actionNone,
}

class LockScreen extends HookWidget {
  const LockScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final action = useState<AfterSelectAction>(AfterSelectAction.actionNone);
    final error = useState<String?>(null);
    final currentPin = useState<String>("");
    final loading = useState<bool>(false);
    final status = useState<String>("LOCKED");

    return Scaffold(
      body: SafeArea(
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          //mainAxisSize: MainAxisSize.max,
          children: [
            Hero(
              tag: "anon_logo",
              child: Semantics(
                label: 'anon',
                child: SizedBox(
                  width: 180, child: Image.asset("assets/anon_logo.png"))),
            ),
            Text(status.value),
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
                      onKeyPress: (String key, String value) {
                        currentPin.value = value;
                        error.value = null;
                      },
                      minPinSize: minPinSize,
                      onSubmit: (String pin) {
                        onSubmit(pin, context, ref, error, loading,
                            action.value, status);
                      },
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 42),
              child: Consumer(
                builder: (context, ref, c) {
                  return Row(
                    children: [
                      const Spacer(),
                      Semantics(
                        label: 'quick receive',
                        child: InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: () {
                          onSubmit(currentPin.value, context, ref, error,
                              loading, AfterSelectAction.actionReceive, status);
                        },
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationX(math.pi),
                            child: const Icon(
                              Icons.arrow_outward,
                              size: 75,
                              color: null,),
                          ),
                        ),
                        ),
                      ),
                      const Spacer(),
                      Semantics(
                        label: 'quick send',
                        child: InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: () {
                          onSubmit(currentPin.value, context, ref, error,
                              loading, AfterSelectAction.actionSend, status);
                        },
                        child: Icon(
                          Icons.arrow_outward,
                          size: 75,
                          color: colorScheme.primary,
                        ),
                      ),
                      ),
                      const Spacer(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onSubmit(
      String pin,
      BuildContext context,
      WidgetRef ref,
      ValueNotifier<String?> error,
      ValueNotifier<bool> loading,
      AfterSelectAction action,
      ValueNotifier<String> status) async {
    try {
      status.value = "UNLOCKING";
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
        if (isViewOnly) {
          storePassword(pin);
        }
        scheduleAutolockTimer();
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (c) => WalletHome(startScreen: getStartScreen(action)),
                settings: const RouteSettings(name: "/")),
            (route) => false);
      }
    } on PlatformException catch (e) {
      status.value = "LOCKED";
      error.value = e.message;
    } catch (e) {
      status.value = "LOCKED";
      debugPrint(e.toString());
    } finally {
      loading.value = false;
    }
  }
}

int getStartScreen(AfterSelectAction action) {
  switch (action) {
    case AfterSelectAction.actionReceive:
      return 1;
    case AfterSelectAction.actionSend:
      return 2;
    case AfterSelectAction.actionNone:
      return 0;
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

  final confOk = await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      autoStartOnBoot: false,
      isForegroundMode: false,

      notificationChannelId: 'anon_foreground',
      initialNotificationTitle: 'anon',
      initialNotificationContent: 'Loading wallet',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );
  if (!confOk) {
    debugPrint(
      "WARN: Failed to service.configure. Background mode will not work as expected",
    );
  }
  await setStats('Loading wallet...');
  final startOk = await service.startService();
  if (!startOk) {
    debugPrint("WARN: failed to start service");
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: kDebugMode ? 1 : 10), (timer) async {
    if (await getStatsExist() == false) {
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      await service.stopSelf();
      timer.cancel();
      return;
    }
    if (service is AndroidServiceInstance) {
      flutterLocalNotificationsPlugin.show(
        notificationId,
        "[ΛИ0ИΞR0]",
        await getStats(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'anon_foreground',
            'Anon Foreground Notification',
            icon: 'anon_mono',
            ongoing: true,
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
            showWhen: false,
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
      );
    }
  });
}
