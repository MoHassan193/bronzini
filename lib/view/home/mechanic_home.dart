import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:me/view/auth/cubit/auth_cubit.dart';
import 'package:me/view/auth/cubit/auth_state.dart';
import 'package:me/view/home/profile_mec.dart';
import 'package:me/view/user/user_home.dart';

import '../../model/utils/constant.dart';
import '../../model/utils/show.dart';
import 'all_details.dart';
import 'item/screens/items.dart';
import 'item/screens/my_items.dart';

class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkUserAuth();
  }

  Future<void> _checkUserAuth() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) {
      _redirectToUserHome();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        _userData = doc.data();
        final userRole = _userData?['role'];

        if (userRole != 'mechanic' && userRole != 'workshop') {
          Show.mo('هذه الصفحة للخبير صيانة سياراتين وأصحاب الورش فقط', Colors.red);
          _redirectToUserHome();
          return;
        }
      } else {
        Show.mo('لم يتم العثور على بيانات المستخدم', Colors.red);
        _redirectToUserHome();
        return;
      }
    } catch (e) {
      Show.mo('خطأ في التحقق من البيانات: $e', Colors.red);
      _redirectToUserHome();
      return;
    }

    setState(() => _loading = false);
  }

  void _redirectToUserHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UserHomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const caramel = Color(0xFFC68B59);
    const ivory = Color(0xFFFFF7EE);
    const cacao = Color(0xFF4E342E);

    if (_loading) {
      return Scaffold(
        backgroundColor: ivory,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: caramel),
              SizedBox(height: 16.h),
              Text(
                'جاري التحقق من البيانات...',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: cacao,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // تحديد النوع وعنوان التطبيق
    final bool isWorkshop = _userData?['role'] == 'workshop';
    final String userTypeText = isWorkshop ? 'ورشة' : 'خبير صيانة سيارات';

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          _redirectToUserHome();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text('لوحة ال$userTypeText'),
              if (_userData != null)
                Text(
                  _userData!['name'] ?? 'مرحباً',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          backgroundColor: caramel,
          foregroundColor: ivory,
          elevation: 2,
          leading:             _buildStatsButton(),

          // IconButton(
          //   icon: Container(
          //     padding: EdgeInsets.all(6.r),
          //     decoration: BoxDecoration(
          //       color: ivory.withOpacity(0.2),
          //       borderRadius: BorderRadius.circular(8.r),
          //     ),
          //     child: Icon(
          //       isWorkshop ? Icons.inventory_2_rounded : Icons.build_rounded,
          //       color: ivory,
          //       size: 20.r,
          //     ),
          //   ),
          //   tooltip: itemTypeText,
          //   onPressed: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => const MyItemsPage()),
          //   ),
          // ),
          actions: [
            SizedBox(width: 8.w),

            IconButton(
              icon: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: ivory.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.person_rounded, color: ivory, size: 20.r),
              ),
              tooltip: 'الملف الشخصي',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditMechanicProfileScreen()),
              ),
            ),
            SizedBox(width: 8.w),
            IconButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MechanicHomeSc()),
                );
              },
              icon: Icon(Icons.home_rounded, color: ivory, size: 20.r),
            ),
            SizedBox(width: 8.w),
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.logout_rounded, color: ivory, size: 20.r),
              ),
              tooltip: 'تسجيل الخروج',
              onPressed: () => _showLogoutDialog(),
            ),
            SizedBox(width: 8.w),
          ],
        ),
        backgroundColor: ivory,
        body: RefreshIndicator(
          onRefresh: _checkUserAuth,
          color: caramel,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfoCard(),
                SizedBox(height: 20.h),

                Text(
                  'التصنيفات المتاحة',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: cacao,
                  ),
                ),
                SizedBox(height: 12.h),

                Expanded(
                  child: GridView.builder(
                    itemCount: mechanicCategories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 16.w,
                      childAspectRatio: 8 / 3,
                    ),
                    itemBuilder: (_, i) {
                      final cat = mechanicCategories[i];
                      final icon = _categoryIcon(i);
                      final gradientColors = _categoryGradients(i);

                      return InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemsPage(category: cat),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors.first.withOpacity(.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -20,
                                top: -20,
                                child: Container(
                                  width: 80.w,
                                  height: 80.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Icon(
                                        icon,
                                        color: ivory,
                                        size: 28.r,
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          color: ivory,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: ivory.withOpacity(0.7),
                                      size: 16.r,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    const caramel = Color(0xFFC68B59);
    const cacao = Color(0xFF4E342E);
    final bool isWorkshop = _userData?['role'] == 'workshop';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: caramel.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: caramel.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [caramel, caramel.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Icon(
              isWorkshop ? Icons.garage_rounded : Icons.build_rounded,
              color: Colors.white,
              size: 24.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، ${_userData?['name'] ?? 'مستخدم'}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: cacao,
                  ),
                ),
                Text(
                  isWorkshop ? 'صاحب ورشة' : 'خبير صيانة سيارات',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: caramel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_userData?['phone'] != null)
                  Text(
                    _userData!['phone'],
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.verified_user,
            color: caramel,
            size: 20.r,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsButton() {
    return FutureBuilder<int>(
      future: _getUserItemsCount(),
      builder: (context, snapshot) {
        return IconButton(
          icon: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7EE).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.analytics_rounded, color: const Color(0xFFFFF7EE), size: 20.r),
              ),
              if (snapshot.hasData && snapshot.data! > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${snapshot.data}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'الإحصائيات',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyItemsPage()),
          ),
        );
      },
    );
  }

  Future<int> _getUserItemsCount() async {
    try {
      if (_currentUser == null) return 0;

      // فلترة حسب نوع المستخدم
      final String itemType = _userData?['role'] == 'workshop' ? 'product' : 'service';

      final snapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('mechanicId', isEqualTo: _currentUser!.uid)
          .where('type', isEqualTo: itemType)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(int index) {
    const list = [
      Icons.build_rounded,
      Icons.car_repair_rounded,
      Icons.handyman_rounded,
      Icons.miscellaneous_services_rounded,
    ];
    return list[index % list.length];
  }

  List<Color> _categoryGradients(int index) {
    const gradients = [
      [Color(0xFFC68B59), Color(0xFFD4A574)],
      [Color(0xFF8D6E63), Color(0xFFA1887F)],
      [Color(0xFF6D4C41), Color(0xFF8D6E63)],
      [Color(0xFF5D4037), Color(0xFF6D4C41)],
    ];
    return gradients[index % gradients.length];
  }
}