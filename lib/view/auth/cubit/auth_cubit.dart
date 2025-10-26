import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? get currentUid => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String name,
    required String password,
    required String phone,
    required String role,
  }) async {
    emit(AuthLoading());

    if (!phone.startsWith('+218')) {
      emit(AuthError('يجب إدخال رقم ليبي يبدأ بـ +218'));
      return;
    }

    try {
      // إنشاء إيميل وهمي من رقم الهاتف
      final emailFake = '${phone.replaceAll('+', '')}@me.ly';

      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailFake,
        password: password,
      );

      // حفظ بيانات المستخدم في Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'phone': phone,
        'email': emailFake,
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      emit(AuthAuthenticated(
        role: role,
        name: name,
        phone: phone,
      ));
    } catch (e) {
      emit(AuthError(_getErrorMessage(e.toString())));
    }
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    emit(AuthLoading());

    try {
      // البحث عن المستخدم بالهاتف
      final userQuery = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        emit(AuthError('المستخدم غير موجود'));
        return;
      }

      final userData = userQuery.docs.first.data();
      final userRole = userData['role'] as String;
      final userName = userData['name'] as String;

      final email = '${phone.replaceAll('+', '')}@me.ly';

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      emit(AuthAuthenticated(
        role: userRole,
        name: userName,
        phone: phone,
      ));
    } catch (e) {
      emit(AuthError(_getErrorMessage(e.toString())));
    }
  }

  void logout() async {
    try {
      await _auth.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError('خطأ في تسجيل الخروج'));
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'المستخدم غير موجود';
    } else if (error.contains('wrong-password')) {
      return 'كلمة السر غير صحيحة';
    } else if (error.contains('email-already-in-use')) {
      return 'رقم الهاتف مستخدم بالفعل';
    } else if (error.contains('weak-password')) {
      return 'كلمة السر ضعيفة';
    } else {
      return 'حدث خطأ: $error';
    }
  }
}