import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rxdart/rxdart.dart';

import 'firebase_options.dart';

// Define a stream controller to pass messages from event handler to the UI
final _messageStreamController = BehaviorSubject<RemoteMessage>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request permission
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (kDebugMode) {
    print('Permission granted: ${settings.authorizationStatus}');
  }

  // Register with FCM and get registration token
  String? token = await messaging.getToken();
  if (kDebugMode) {
    print('Registration Token=$token');
  }

  // Set up foreground message handler
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (kDebugMode) {
      print('Handling a foreground message: ${message.messageId}');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification?.title}');
      print('Message notification: ${message.notification?.body}');
    }

    // Pass the message to the stream controller
    _messageStreamController.sink.add(message);
  });

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Awesome Notifications
  AwesomeNotifications().initialize("resource://drawable/logo", [
    NotificationChannel(
      channelKey: 'pra Channel',
      channelName: 'pra Notification Channel',
      channelDescription: 'pra Notification Channel',
      defaultColor: Colors.white,
      channelShowBadge: true,
      ledColor: Colors.white,
      playSound: true,
      importance: NotificationImportance.Max,
      enableVibration: true,
      vibrationPattern: highVibrationPattern,
      enableLights: true,
      onlyAlertOnce: false,
      defaultPrivacy: NotificationPrivacy.Public,
      locked: true,
      icon: "resource://drawable/logo",
    ),
  ]);
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      // This is just a basic example. For real apps, you must show some
      // friendly dialog box before call the request method.
      // This is very important to not harm the user experience
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
  runApp(const MyApp());
}

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
    print('Message notification: ${message.notification?.body}');
  }

  // Show a local notification
  showLocalNotification(message.notification?.title ?? 'Background Notification', message.notification?.body ?? 'You have a new background notification!');
}

// Define a method to show local notifications
void showLocalNotification(String title, String body) async {
  AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2021,
        channelKey: 'pra Channel',
        actionType: ActionType.Default,
        title: 'Hello World!',
        body: 'This is my first notification!',
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    showLocalNotification(
        'Scroll Notification', 'You have reached the middle position!');
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    double scrollPosition = _scrollController.position.pixels;
    double middlePosition = _scrollController.position.maxScrollExtent / 2.5;

    if (scrollPosition >= middlePosition) {
      // Show a local notification
      showLocalNotification(
          'Scroll Notification', 'You have reached the middle position!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Awesome Notifications"),
        leading: const Icon(
          Icons.notifications,
          size: 20,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder<RemoteMessage>(
              stream: _messageStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final message = snapshot.data!;
                  if (message.notification != null) {
                    return Column(
                      children: [
                        Text('Last message from Firebase Messaging:',
                          style: Theme
                              .of(context)
                              .textTheme
                              .headline6,),
                        Text('Title: ${message.notification?.title}',
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodyText1,),
                        Text('Body: ${message.notification?.body}',
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodyText1,),
                      ],
                    );
                  } else {
                    return Text('Received a data message: ${message.data}',
                      style: Theme
                          .of(context)
                          .textTheme
                          .headline6,);
                  }
                } else {
                  return Text('No messages yet', style: Theme
                      .of(context)
                      .textTheme
                      .headline6,);
                }
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Number of items in the list
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Item ${index + 1}'),
                    onTap: () {
                      // Trigger a notification when the item is tapped
                      showLocalNotification(
                          'Notification', 'You tapped on item ${index + 1}');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

