import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/models/item.dart';
import '../../model/models/mechanic_model.dart';
import '../home/item/screens/item_details.dart';

const caramel = Color(0xFFC68B59);
const ivory   = Color(0xFFFFF7EE);
const cacao   = Color(0xFF5D4037);

class MechanicProductsPage extends StatelessWidget {
  final Mechanic mechanic;
  const MechanicProductsPage({super.key, required this.mechanic});

  @override
  Widget build(BuildContext context) {
    // تحديد النوع بناء على role الخبير صيانة سيارات
    final String itemType = mechanic.role == 'workshop' ? 'product' : 'service';
    final String titleText = mechanic.role == 'workshop' ? 'منتجات' : 'خدمات';

    return Scaffold(
      appBar: AppBar(
        title: Text('$titleText ${mechanic.name}'),
        backgroundColor: caramel,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: ivory,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .where('mechanicId', isEqualTo: mechanic.id)
            .where('type', isEqualTo: itemType) // فلترة حسب النوع
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.r, color: Colors.red),
                  SizedBox(height: 16.h),
                  const Text('حدث خطأ في تحميل البيانات'),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('العودة'),
                  ),
                ],
              ),
            );
          }

          if (!snap.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: caramel),
                  SizedBox(height: 16.h),
                  Text(
                    'جاري تحميل ${titleText}...',
                    style: TextStyle(color: caramel, fontSize: 16.sp),
                  ),
                ],
              ),
            );
          }

          final items = snap.data!.docs;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    mechanic.role == 'workshop'
                        ? Icons.inventory_2_outlined
                        : Icons.build_outlined,
                    size: 64.r,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'لا توجد $titleText متاحة حالياً',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: cacao,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'تحقق مرة أخرى لاحقاً',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // معلومات الخبير صيانة سيارات/صاحب تاجر قطع غيار 
              Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: caramel.withOpacity(0.3)),
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
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [caramel, caramel.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        mechanic.role == 'workshop'
                            ? Icons.garage_rounded
                            : Icons.build_rounded,
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
                            mechanic.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: cacao,
                            ),
                          ),
                          Text(
                            mechanic.role == 'workshop' ? 'ورشة متخصصة' : 'خبير صيانة سيارات محترف',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: caramel,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (mechanic.phone.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14.r, color: Colors.grey),
                                SizedBox(width: 4.w),
                                Text(
                                  mechanic.phone,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: caramel.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${items.length} ${titleText.substring(0, titleText.length - 1)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: caramel,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // قائمة المنتجات/الخدمات
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
                  separatorBuilder: (_, __) => SizedBox(height: 14.h),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final d = items[i].data()! as Map<String, dynamic>;
                    final item = ItemModel.fromDoc(items[i].id, d);

                    return InkWell(
                      borderRadius: BorderRadius.circular(18.r),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailsScreen(item: item),
                        ),
                      ),
                      child: _ItemCard(
                        item: item,
                        isService: mechanic.role == 'mechanic',
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ItemModel item;
  final bool isService;

  const _ItemCard({
    required this.item,
    required this.isService,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 3,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: LinearGradient(
            colors: [ivory, caramel.withOpacity(.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: caramel.withOpacity(.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            // الصورة
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: item.images.isNotEmpty
                  ? Image.network(
                item.images.first,
                height: 80.h,
                width: 80.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80.h,
                  width: 80.w,
                  color: Colors.grey.shade200,
                  child: Icon(
                    isService ? Icons.build : Icons.inventory_2,
                    color: Colors.grey,
                    size: 32.r,
                  ),
                ),
              )
                  : Container(
                height: 80.h,
                width: 80.w,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isService ? Icons.build : Icons.inventory_2,
                  color: Colors.grey,
                  size: 32.r,
                ),
              ),
            ),
            SizedBox(width: 14.w),

            // النصوص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: cacao,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isNew)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'جديد',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  Row(
                    children: [
                      Icon(
                        isService ? Icons.build : Icons.category,
                        size: 12.r,
                        color: caramel,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${isService ? 'خدمة' : 'منتج'}: ${item.category}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: cacao.withOpacity(.85),
                        ),
                      ),
                    ],
                  ),

                  if (item.price != null) ...[
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 12.r,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          item.formattedPrice,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (item.description?.isNotEmpty ?? false) ...[
                    SizedBox(height: 4.h),
                    Text(
                      item.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // سهم للانتقال
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: caramel.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: caramel,
                size: 16.r,
              ),
            ),
          ],
        ),
      ),
    );
  }
}