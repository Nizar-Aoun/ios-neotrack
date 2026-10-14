// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:taxi_driver_app/router.dart';
// import 'package:taxi_driver_app/services/auth_service.dart';
// import 'package:taxi_driver_app/services/user_service.dart';
// import 'package:taxi_driver_app/providers/user_provider.dart';
// import 'package:taxi_driver_app/core/shared/loading_gif.dart';

// class RootScreen extends StatefulWidget {
//   final String? currentPassword;

//   const RootScreen({
//     super.key,
//     this.currentPassword,
//   });

//   @override
//   State<RootScreen> createState() => _RootScreenState();
// }

// class _RootScreenState extends State<RootScreen> {
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     print("--------------------------------");
//     _loadVersion();
//     _checkAuthAndFetchUser();
//   }

//   Future<void> _loadVersion() async {
//     final packageInfo = await PackageInfo.fromPlatform();
//     print('*************');
//     print('App version: ${packageInfo.version}');
//   }

//   Future<void> _checkAuthAndFetchUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     final authService = AuthService(prefs);
//     final userService = UserService(authService);
//     final userProvider = Provider.of<UserProvider>(context, listen: false);
//     final token = await authService.getToken();
//     final userId = await authService.getUserId();

//     if (token != null && userId != null) {
//       try {
//         final user = await userService.getCurrentUser(token, userId);
//         debugPrint(
//             'RootScreen - User fetched: ${user.fullName}, passwordUpdated: ${user.passwordUpdated}');
//         userProvider.setUser(user);
//         debugPrint(
//             'RootScreen - User set in provider, passwordUpdated: ${userProvider.user?.passwordUpdated}');

//         if (mounted) {
//           print('RootScreen - User is authenticated');
//           // Check if user needs to set password
//           final user = userProvider.user;
//           if (user == null) {
//             print('RootScreen - No user found, going to login');
//             Get.offAllNamed(Routes.login);
//           } else {
//             final needsPassword = !user.passwordUpdated;
//             print('RootScreen - User needs password: $needsPassword');

//             if (needsPassword) {
//               if (widget.currentPassword == null) {
//                 print(
//                     'RootScreen - No current password provided, going to login');
//                 Get.offAllNamed(Routes.login);
//                 return;
//               }
//               print('RootScreen - Navigating to CreatePasswordScreen');
//               Get.offAllNamed(Routes.createPassword,
//                   arguments: widget.currentPassword ?? '');
//             } else {
//               print('RootScreen - Navigating to HomeScreen');
//               Get.offAllNamed(Routes.home);
//             }
//           }
//         }
//       } catch (e) {
//         print('RootScreen - Error fetching user: $e');
//         // If fetching user fails, go to login
//         if (mounted) {
//           Get.offAllNamed(Routes.login);
//         }
//       }
//     } else {
//       debugPrint('RootScreen - No token or userId found, going to login');
//       // Not authenticated, go to login
//       if (mounted) {
//         Get.offAllNamed(Routes.login);
//       }
//     }

//     if (mounted) setState(() => _loading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: _loading
//             ? const LoadingGif(width: 60, height: 60)
//             : const SizedBox.shrink(),
//       ),
//     );
//   }
// }
