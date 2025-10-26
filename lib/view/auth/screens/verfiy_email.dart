// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../model/utils/show.dart';
// import '../cubit/auth_cubit.dart';
// import '../cubit/auth_state.dart';   // Show.mo
//
// class VerifyEmailScreen extends StatefulWidget {
//   const VerifyEmailScreen({super.key});
//
//   @override
//   State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
// }
//
// class _VerifyEmailScreenState extends State<VerifyEmailScreen>
//     with WidgetsBindingObserver {
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//
//     // فحص دوري كل 5 ثوانٍ
//     _timer = Timer.periodic(const Duration(seconds: 5), (_) {
//       context.read<AuthCubit>().checkEmailVerified();
//     });
//   }
//
//   // يتحقّق عند الرجوع للتطبيق بعد فتح تطبيق البريد
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       context.read<AuthCubit>().checkEmailVerified();
//     }
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const beige = Color(0xFFF5F0E3);
//     const brown = Color(0xFF795548);
//
//     return Scaffold(
//       backgroundColor: beige,
//       body: SafeArea(
//         child: BlocListener<AuthCubit, AuthState>(
//           listener: (context, state) {
//             if (state is AuthAuthenticated) {
//               _timer?.cancel();
//               Show.mo('تم التفعيل بنجاح', brown);
//               Navigator.pushReplacementNamed(context, '/home');
//             }
//           },
//           child: Center(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.email_outlined, size: 120),
//                   const SizedBox(height: 24),
//                   const Text(
//                     'تحقَّق من بريدك الإلكتروني واضغط على رابط التفعيل، '
//                         'وسينقلك التطبيق تلقائيًا بمجرد التفعيل.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 18),
//                   ),
//                   const SizedBox(height: 32),
//                   const CircularProgressIndicator(color: brown),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
