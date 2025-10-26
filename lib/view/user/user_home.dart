import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../model/models/mechanic_model.dart';
import '../../model/utils/constant.dart';
import '../home/item/screens/items.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import 'mechanic_product.dart';


const caramel = Color(0xFFC68B59);


class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  static const caramel = Color(0xFFC68B59);
  static const ivory = Color(0xFFF8F6F0);
  static const cacao = Color(0xFF4E342E);

  User? _currentUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      if (_currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data();
          });
        }
      }
    } catch (e) {
      print('خطأ في جلب بيانات المستخدم: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.role == 'mechanic' || state.role == 'workshop') {
            Navigator.pushReplacementNamed(context, '/mechHome');
          } else {
            _checkCurrentUser();
          }
        } else if (state is AuthInitial) {
          setState(() {
            _currentUser = null;
            _userData = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentUser != null
                ? 'مرحباً، ${_userData?['name'] ?? 'مستخدم'}'
                : 'عالم السيارات',
            style: TextStyle(fontSize: 16.sp),
          ),
          backgroundColor: caramel,
          foregroundColor: ivory,
          centerTitle: true,
          elevation: 1,
          actions: [
            if (_currentUser != null) ...[
              PopupMenuButton<String>(
                icon: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: ivory.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.person_rounded, color: ivory, size: 20.r),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      _showProfileDialog();
                      break;
                    case 'logout':
                      _showLogoutDialog();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16),
                        SizedBox(width: 8),
                        Text('الملف الشخصي'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/auth'),
                  icon: Icon(Icons.login_rounded, size: 16.r),
                  label: Text(
                    'دخول',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ivory,
                    foregroundColor: caramel,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: ivory,
        body: RefreshIndicator(
          onRefresh: () async {
            await _fetchUserData();
          },
          color: caramel,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentUser != null)
                    _buildWelcomeCard()
                  else
                    _buildGuestWelcomeCard(),

                  SizedBox(height: 20.h),

                  Row(
                    children: [
                      Icon(Icons.garage_rounded, color: caramel, size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        'أصحاب محل قطع الغيار',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: cacao,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  _buildMechanicSlider(context),

                  SizedBox(height: 24.h),

                  Divider(
                    color: caramel.withOpacity(.4),
                    thickness: 1,
                    height: 24.h,
                  ),

                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      Icon(Icons.category_rounded, color: caramel, size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        'المنتجات والخدمات',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: cacao,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  _buildCategoriesGrid(context),

                  SizedBox(height: 65.h),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _currentUser == null
            ? FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/auth'),
          backgroundColor: caramel,
          foregroundColor: ivory,
          icon: Icon(Icons.build_rounded, size: 20.r),
          label: Text(
            'انضم كخبير صيانة سيارات',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [caramel.withOpacity(0.1), ivory],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: caramel.withOpacity(0.3)),
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
              Icons.person_rounded,
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
                  'مرحباً، ${_userData?['name'] ?? 'مستخدم'}! 👋',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: cacao,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'استكشف أفضل المنتجات والخدمات لسيارتك',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), ivory],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  color: Colors.blue,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك في عالم السيارات! 🚗',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: cacao,
                      ),
                    ),
                    Text(
                      'تصفح المنتجات والخدمات مجاناً',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/auth'),
                  icon: Icon(Icons.login_rounded, size: 16.r),
                  label: Text(
                    'تسجيل دخول',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/auth'),
                  icon: Icon(Icons.person_add_rounded, size: 16.r),
                  label: Text(
                    'حساب جديد',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: caramel,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicSlider(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['mechanic', 'workshop'])
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Container(
            height: 180.h,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 32.r),
                  SizedBox(height: 8.h),
                  const Text('حدث خطأ في تحميل البيانات'),
                ],
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return Container(
            height: 180.h,
            decoration: BoxDecoration(
              color: caramel.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: caramel),
                  SizedBox(height: 12.h),
                  Text('جاري تحميل الورش...',
                      style: TextStyle(color: caramel, fontSize: 12.sp)),
                ],
              ),
            ),
          );
        }

        final mechanics =
        snap.data!.docs.map((d) => Mechanic.fromDoc(d)).toList();

        if (mechanics.isEmpty) {
          return Container(
            height: 200.h,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.garage_outlined, color: Colors.grey, size: 32.r),
                  SizedBox(height: 8.h),
                  const Text('لا يوجد ورش متاحة حالياً'),
                  SizedBox(height: 8.h),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/auth'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('كن أول خبير صيانة سيارات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: caramel,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 240.h, // ✔️ زوّدنا الارتفاع
          child: CarouselSlider.builder(
            itemCount: mechanics.length,
            itemBuilder: (ctx, i, _) => _MechanicCard(
              mechanic: mechanics[i],
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => MechanicProductsPage(mechanic: mechanics[i]),
                ),
              ),
            ),
            options: CarouselOptions(
              height: 240.h,
              viewportFraction: 0.82,
              enlargeCenterPage: true,
              autoPlay: mechanics.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              enableInfiniteScroll: mechanics.length > 1,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: mechanicCategories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (_, i) {
        final cat = mechanicCategories[i];
        final icon = _categoryIcon(i);
        final colors = _categoryColors(i);

        return InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItemsPage(category: cat)),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withOpacity(.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  top: -15,
                  child: Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(icon, color: ivory, size: 28.r),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        cat,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ivory,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8.h,
                  right: 8.w,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: ivory.withOpacity(0.7),
                    size: 12.r,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person, color: caramel, size: 24.r),
            SizedBox(width: 8.w),
            const Text('الملف الشخصي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileRow('الاسم', _userData?['name'] ?? 'غير محدد'),
            _ProfileRow('الهاتف', _userData?['phone'] ?? 'غير محدد'),
            _ProfileRow('البريد', _currentUser?.email ?? 'غير محدد'),
            _ProfileRow('النوع', _userData?['role'] == 'mechanic' ? 'خبير صيانة سيارات' :
            _userData?['role'] == 'workshop' ? 'صاحب ورشة' : 'مستخدم'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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

  List<Color> _categoryColors(int index) {
    const colors = [
      [Color(0xFFC68B59), Color(0xFFD4A574)],
      [Color(0xFF8D6E63), Color(0xFFA1887F)],
      [Color(0xFF6D4C41), Color(0xFF8D6E63)],
      [Color(0xFF5D4037), Color(0xFF6D4C41)],
    ];
    return colors[index % colors.length];
  }
}

class _MechanicCard extends StatelessWidget {
  final Mechanic mechanic;
  final VoidCallback onTap;
  const _MechanicCard({required this.mechanic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = mechanic.photoUrl; // تأكد إن الموديل عنده الحقل ده
    final heroTag = 'mech_${mechanic.id}_${imageUrl ?? 'noimg'}';

    return InkWell(
      onTap: onTap, // ضغط الكارت كله -> صفحة المنتجات
      borderRadius: BorderRadius.circular(16.r),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الصورة (اضغط عليها فقط تفتح فول سكرين)
            GestureDetector(
              onTap: imageUrl == null || imageUrl.isEmpty
                  ? null
                  : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullscreenImagePage(
                      imageUrl: imageUrl,
                      tag: heroTag,
                    ),
                  ),
                );
              },
              child: Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9, // مساحة صورة أكبر ومرتبة
                    child: imageUrl == null || imageUrl.isEmpty
                        ? Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_not_supported_outlined,
                          size: 32.r, color: Colors.grey),
                    )
                        : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, w, progress) {
                        if (progress == null) return w;
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.r),
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                  (progress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (c, e, s) => Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // معلومات مختصرة أسفل الصورة
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mechanic.name ?? 'بدون اسم',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16.r, color: caramel),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            mechanic.address ?? 'غير محدد',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: caramel.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          mechanic.role == 'workshop'
                              ? 'ورشة متخصصة'
                              : 'خبير صيانة سيارات',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: caramel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullscreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String tag;
  const FullscreenImagePage({super.key, required this.imageUrl, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // تكبير/تصغير
          Center(
            child: Hero(
              tag: tag,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Icon(
                      Icons.broken_image_outlined, color: Colors.white70, size: 48.r),
                ),
              ),
            ),
          ),
          // زر الرجوع
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12.r, color: color.withOpacity(0.7)),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}