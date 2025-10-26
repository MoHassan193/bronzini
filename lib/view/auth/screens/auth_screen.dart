import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:me/view/auth/screens/verfiy_email.dart';

import '../../../model/utils/show.dart';
import '../../user/user_home.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beige = const Color(0xFFF8F6F0);
    final brown = const Color(0xFF6D4C41);
    final accent = const Color(0xFF8D6E63);

    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        backgroundColor: beige,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: brown,
          labelColor: brown,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
          unselectedLabelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
          tabs: [
            Tab(child: Text('تسجيل الدخول')),
            Tab(child: Text('إنشاء حساب')),
          ],
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            Show.mo(state.message, Colors.red);
          }
          if (state is AuthAuthenticated) {
            if (state.role == 'mechanic' || state.role == 'workshop') {
              Navigator.pushReplacementNamed(context, '/mechHome');
            } else {
              Navigator.pushReplacementNamed(context, '/userHome');
            }
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return TabBarView(
            controller: _tab,
            children: [
              _LoginForm(disabled: loading),
              _RegisterForm(disabled: loading),
            ],
          );
        },
      ),
    );
  }
}

// نموذج تسجيل الدخول
class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.disabled});
  final bool disabled;
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _phone.text = '';
  }

  @override
  Widget build(BuildContext context) {
    final brown = const Color(0xFF6D4C41);
    final accent = const Color(0xFF8D6E63);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Form(
        key: _form,
        child: Column(
          children: [
            // لوجو مع تصميم مربع أنيق
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  colors: [brown, accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brown.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17.r),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17.r),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            Text(
              'مرحباً بك مرة أخرى',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: brown,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'سجل دخولك للمتابعة',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24.h),

            _phoneField(
              _phone,
              'رقم الهاتف',
              Icons.phone_rounded,
              validator: (v) {
                if (v!.isEmpty) return 'رقم الهاتف مطلوب';
                if (v.length != 9) return 'رقم الهاتف يجب أن يكون 9 أرقام';
                return null;
              },
            ),
            SizedBox(height: 14.h),

            _passwordField(
              _password,
              'كلمة السر',
              Icons.lock_rounded,
              showPassword: _showPassword,
              onToggleVisibility: () => setState(() => _showPassword = !_showPassword),
              validator: (v) => v!.length < 6 ? 'كلمة السر يجب أن تكون 6 أحرف على الأقل' : null,
            ),
            SizedBox(height: 26.h),

            // زر تسجيل الدخول
            Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: LinearGradient(
                  colors: [brown, accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brown.withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: widget.disabled
                    ? null
                    : () {
                  if (_form.currentState!.validate()) {
                    final fullPhone = '+218${_phone.text.trim()}';
                    context.read<AuthCubit>().login(
                      phone: fullPhone,
                      password: _password.text,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: widget.disabled
                    ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // زر التصفح كمستخدم
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                );
              },
              child: Container(
                width: 200.w,
                height: 150.h,
                margin: EdgeInsets.symmetric(horizontal: (MediaQuery.of(context).size.width - 120.w) / 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade700],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 28.r,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'تصفح كمستخدم',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // زر التصفح كمستخدم - مربع كبير
          ],
        ),
      ),
    );
  }
}

// نموذج إنشاء حساب
class _RegisterForm extends StatefulWidget {
  const _RegisterForm({required this.disabled});
  final bool disabled;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _form = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  String _role = 'mechanic'; // افتراضي
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _phoneCtl.text = '';
  }

  @override
  Widget build(BuildContext context) {
    final brown = const Color(0xFF6D4C41);
    final accent = const Color(0xFF8D6E63);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Form(
        key: _form,
        child: Column(
          children: [
            CircleAvatar(
              radius: 60.r,
              backgroundImage: const AssetImage('assets/logo.png'),
            ),
            SizedBox(height: 16.h),

            Text(
              'إنشاء حساب جديد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: brown,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'املأ البيانات للبدء',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20.h),

            _textField(
              _nameCtl,
              'الاسم الكامل',
              Icons.person_rounded,
              validator: (v) => v!.isEmpty ? 'الاسم مطلوب' : null,
            ),
            SizedBox(height: 14.h),

            _phoneField(
              _phoneCtl,
              'رقم الهاتف',
              Icons.phone_rounded,
              validator: (v) {
                if (v!.isEmpty) return 'رقم الهاتف مطلوب';
                if (v.length != 9) return 'رقم الهاتف يجب أن يكون 9 أرقام';
                return null;
              },
            ),
            SizedBox(height: 14.h),

            _passwordField(
              _passCtl,
              'كلمة السر',
              Icons.lock_rounded,
              showPassword: _showPassword,
              onToggleVisibility: () =>
                  setState(() => _showPassword = !_showPassword),
              validator: (v) =>
              v!.length < 6 ? 'كلمة السر يجب أن تكون 6 أحرف على الأقل' : null,
            ),
            SizedBox(height: 18.h),

            // اختيار نوع الحساب
            _rolePicker(),

            SizedBox(height: 26.h),

            // زر إنشاء الحساب
            Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: LinearGradient(
                  colors: [brown, accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brown.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: widget.disabled
                    ? null
                    : () {
                  if (_form.currentState!.validate()) {
                    final fullPhone = '+218${_phoneCtl.text.trim()}';
                    debugPrint('ROLE BEFORE REGISTER: $_role'); // ✅ تأكيد
                    context.read<AuthCubit>().register(
                      name: _nameCtl.text,
                      password: _passCtl.text,
                      phone: fullPhone,
                      role: _role,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: widget.disabled
                    ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : Text(
                  'إنشاء الحساب',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// عنصر اختيار نوع الحساب (تم تعديله بالكامل)
  Widget _rolePicker() {
    final brown = const Color(0xFF6D4C41);
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نوع الحساب',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: brown,
            ),
          ),
          SizedBox(height: 10.h),
          RadioListTile<String>(
            value: 'mechanic',
            groupValue: _role,
            activeColor: brown,
            dense: true,
            onChanged: (v) => setState(() => _role = v!),
            title: Text(
              'خبير صيانة سيارات',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
          RadioListTile<String>(
            value: 'workshop',
            groupValue: _role,
            activeColor: brown,
            dense: true,
            onChanged: (v) => setState(() => _role = v!),
            title: Text(
              'تاجر قطع غيار',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}


// حقل رقم الهاتف مع كود البلد على اليسار
Widget _phoneField(
    TextEditingController ctl,
    String hint,
    IconData icon, {
      String? Function(String?)? validator,
    }) =>
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: ctl,
        keyboardType: TextInputType.phone,
        validator: validator,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: EdgeInsets.all(10.r),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF6D4C41).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16.r, color: const Color(0xFF6D4C41)),
                SizedBox(width: 6.w),
                Text(
                  '+218',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6D4C41),
                  ),
                ),
              ],
            ),
          ),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: const Color(0xFF6D4C41), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
        ),
      ),
    );

// حقل كلمة السر
Widget _passwordField(
    TextEditingController ctl,
    String hint,
    IconData icon, {
      required bool showPassword,
      required VoidCallback onToggleVisibility,
      String? Function(String?)? validator,
    }) =>
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: ctl,
        obscureText: !showPassword,
        validator: validator,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: EdgeInsets.all(10.r),
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: const Color(0xFF6D4C41).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 16.r, color: const Color(0xFF6D4C41)),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.grey.shade600,
              size: 18.r,
            ),
            onPressed: onToggleVisibility,
          ),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: const Color(0xFF6D4C41), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
        ),
      ),
    );

// حقل نصي عادي
Widget _textField(
    TextEditingController ctl,
    String hint,
    IconData icon, {
      TextInputType keyboard = TextInputType.text,
      String? Function(String?)? validator,
    }) =>
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: ctl,
        keyboardType: keyboard,
        validator: validator,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: EdgeInsets.all(10.r),
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: const Color(0xFF6D4C41).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 16.r, color: const Color(0xFF6D4C41)),
          ),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: const Color(0xFF6D4C41), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
        ),
      ),
    );