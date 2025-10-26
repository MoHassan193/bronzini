// ignore_for_file: use_build_context_synchronously
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../model/models/item.dart';

/*──────────────────────── شاشة تفاصيل المنتج/الخدمة ────────────────────────*/
class ItemDetailsScreen extends StatelessWidget {
  final ItemModel item;
  const ItemDetailsScreen({super.key, required this.item});

  /* جلب بيانات الخبير صيانة سيارات/صاحب تاجر قطع غيار  */
  Future<Map<String, dynamic>?> _getMechanic() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(item.mechanicId)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    /* لوحة ألوان ثابتة */
    const ivory   = Color(0xFFFFF7EE);
    const caramel = Color(0xFFC68B59);
    const cacao   = Color(0xFF5D4037);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.isService ? 'تفاصيل الخدمة' : 'تفاصيل المنتج'),
        backgroundColor: caramel,
        foregroundColor: Colors.white,
      ),
      backgroundColor: ivory,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getMechanic(),
        builder: (_, snap) {
          final mech = snap.data;

          return CustomScrollView(
            slivers: [
              /* رأس مرن بالصور */
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: 260.h,
                pinned: true,
                backgroundColor: caramel,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: item.id,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CarouselSlider.builder(
                          itemCount: item.images.length,
                          itemBuilder: (_, i, __) => Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                item.images[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    item.isService ? Icons.build : Icons.inventory_2,
                                    color: Colors.grey,
                                    size: 64.r,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black26, Colors.transparent],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          options: CarouselOptions(
                            viewportFraction: 1,
                            height: double.infinity,
                            autoPlay: item.images.length > 1,
                            autoPlayInterval: const Duration(seconds: 3),
                          ),
                        ),
                        // علامة النوع
                        Positioned(
                          top: 40.h,
                          left: 16.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: item.isService ? Colors.blue : Colors.green,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              item.isService ? 'خدمة' : 'منتج',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // علامة جديد
                        if (item.isNew)
                          Positioned(
                            top: 40.h,
                            right: 16.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                'جديد',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // عدد الصور
                        if (item.hasMultipleImages)
                          Positioned(
                            bottom: 20.h,
                            right: 16.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_library, color: Colors.white, size: 14.r),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${item.imageCount}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              /* محتوى التفاصيل */
              SliverPadding(
                padding: EdgeInsets.all(20.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    /* اسم + سعر */
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: cacao,
                            ),
                          ),
                        ),
                        if (item.price != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [caramel, caramel.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.payments, size: 16.r, color: Colors.white),
                                SizedBox(width: 4.w),
                                Text(
                                  item.formattedPrice,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    /* معلومات إضافية */
                    Row(
                      children: [
                        Icon(Icons.category, size: 16.r, color: caramel),
                        SizedBox(width: 4.w),
                        Text(
                          'التصنيف: ${item.category}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Icon(Icons.access_time, size: 16.r, color: caramel),
                        SizedBox(width: 4.w),
                        Text(
                          item.formattedCreatedDate,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    /* الوصف داخل DottedBorder + نسخ */
                    if (item.description?.isNotEmpty ?? false) ...[
                      SizedBox(height: 20.h),
                      Text(
                        'الوصف',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: cacao,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: item.description!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ الوصف!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: DottedBorder(
                          color: caramel,
                          strokeWidth: 1.2,
                          dashPattern: const [5, 3],
                          borderType: BorderType.RRect,
                          radius: Radius.circular(10.r),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              children: [
                                Text(
                                  item.description!,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: cacao.withOpacity(.9),
                                    height: 1.6,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.copy, size: 14.r, color: caramel),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'اضغط للنسخ',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: caramel,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    /* بيانات الخبير صيانة سيارات/صاحب تاجر قطع غيار  */
                    SizedBox(height: 28.h),
                    Text(
                      mech?['role'] == 'workshop' ? 'معلومات تاجر قطع غيار ' : 'معلومات الخبير صيانة سيارات',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: cacao,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (snap.connectionState == ConnectionState.waiting)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          child: CircularProgressIndicator(color: caramel),
                        ),
                      ),
                    if (mech != null)
                      _MechanicCard(mech: mech, caramel: caramel, cacao: cacao),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/*──────────────────── بطاقة معلومات الخبير صيانة سيارات/صاحب تاجر قطع غيار  ────────────────────*/
class _MechanicCard extends StatelessWidget {
  final Map<String, dynamic> mech;
  final Color caramel;
  final Color cacao;
  const _MechanicCard({
    required this.mech,
    required this.caramel,
    required this.cacao,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWorkshop = mech['role'] == 'workshop';

    return Card(
      color: caramel.withOpacity(.05),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Header مع الاسم والنوع
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [caramel, caramel.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
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
                        mech['name'] ?? '---',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cacao,
                          fontSize: 16.sp,
                        ),
                      ),
                      Text(
                        isWorkshop ? 'ورشة متخصصة' : 'خبير صيانة سيارات محترف',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: caramel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: caramel.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    isWorkshop ? 'ورشة' : 'خبير صيانة سيارات',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: caramel,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // معلومات الاتصال
            if (mech['phone'] != null && mech['phone'] != '')
              _infoRow(
                icon: Icons.phone,
                text: mech['phone'],
                caramel: caramel,
                cacao: cacao,
                trailing: _iconActions(
                  copyText: mech['phone'],
                  launchUrl: 'tel:${mech['phone']}',
                  whatsappUrl: 'https://wa.me/${mech['phone']}',
                  caramel: caramel,
                  context: context,
                ),
              ),

            if (mech['address'] != null && mech['address'] != '') ...[
              SizedBox(height: 8.h),
              _infoRow(
                icon: Icons.location_on,
                text: mech['address'],
                caramel: caramel,
                cacao: cacao,
                trailing: IconButton(
                  icon: Icon(Icons.copy, size: 18.r),
                  color: caramel,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: mech['address']));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ العنوان!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],

            if (mech['about'] != null && mech['about'] != '') ...[
              SizedBox(height: 8.h),
              _infoRow(
                icon: Icons.info_outline,
                text: mech['about'],
                caramel: caramel,
                cacao: cacao,
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /* صفّ معلومات واحد */
  Widget _infoRow({
    required IconData icon,
    required String text,
    required Color caramel,
    required Color cacao,
    Widget? trailing,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: caramel.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: caramel, size: 16.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, color: cacao),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  /* أزرار نسخ واتصال وواتساب */
  Widget _iconActions({
    required String copyText,
    required String launchUrl,
    required String whatsappUrl,
    required Color caramel,
    required BuildContext context,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.copy, size: 18.r),
          color: caramel,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: copyText));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم نسخ الرقم!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.call, size: 18.r),
          color: Colors.green.shade600,
          onPressed: () => _launchUrl(launchUrl),
        ),
        IconButton(
          icon: Icon(Icons.chat, size: 18.r),
          color: Colors.green.shade700,
          onPressed: () => _launchUrl(whatsappUrl),
        ),
      ],
    );
  }

  void _launchUrl(String url) async {
    try {
      await launchUrlString(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Could not launch $url: $e');
    }
  }
}