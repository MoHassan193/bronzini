import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:me/view/home/item/screens/item_details.dart';

import '../../../../model/models/item.dart';
import '../item_cubit/item_cubit.dart';
import '../item_cubit/item_state.dart';
import 'add_item.dart';
import 'edit_item_page.dart';

const caramel = Color(0xFFC68B59);
const ivory   = Color(0xFFFFF7EE);
const cacao   = Color(0xFF4E342E);

class ItemsPage extends StatelessWidget {
  final String category;
  const ItemsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ItemCubit()..fetchByCategory(category),
      child: _ItemsView(category: category),
    );
  }
}

class _ItemsView extends StatefulWidget {
  final String category;
  const _ItemsView({required this.category});

  @override
  State<_ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<_ItemsView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce لتحسين الأداء مع الكتابة السريعة
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _query = _searchCtrl.text.trim();
      });
    });
  }

  // تبسيط التطبيع للنصوص (Lowercase + أرقام فقط للسعر)
  String _norm(String? s) => (s ?? '').toLowerCase();

  // فحص شامل لكل الحقول الشائعة
  bool _matchesQuery(ItemModel item, String q) {
    if (q.isEmpty) return true;

    final nq = _norm(q);

    // تحويل أرقام عربية-هندية إلى لاتينية (بدائي)
    final arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    String normalizeDigits(String input) {
      final buf = StringBuffer();
      for (final ch in input.characters) {
        final idx = arabicDigits.indexOf(ch);
        if (idx >= 0) {
          buf.write(idx.toString());
        } else {
          buf.write(ch);
        }
      }
      return buf.toString();
    }

    final priceStr = item.price?.toString() ?? '';
    final fields = <String>[
      _norm(item.name),
      _norm(item.description ?? ''),
      _norm(item.category ?? ''),
      _norm(item.formattedPrice),
      _norm(item.formattedCreatedDate),
      item.isService ? 'خدمة service' : 'منتج product',
      item.isNew ? 'new جديد' : 'مستعمل used',
      item.mechanicId ?? '',
      // أي حقول إضافية محتملة:
      // _norm(item.brand ?? ''),
      // _norm(item.model ?? ''),
    ];

    // طابق النص مباشرة
    final textHit = fields.any((f) => f.contains(nq));

    // طابق بالسعر كأرقام (لو المستخدم كتب أرقام فقط)
    final qDigits = normalizeDigits(nq).replaceAll(RegExp(r'[^0-9]'), '');
    final priceHit = qDigits.isNotEmpty && normalizeDigits(priceStr).contains(qDigits);

    return textHit || priceHit;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: caramel,
        centerTitle: true,
        elevation: 1,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
            child: _SearchField(
              controller: _searchCtrl,
              hint: 'ابحث بالاسم، الوصف، السعر، التاريخ، النوع...',
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
          ),
        ),
      ),
      body: BlocBuilder<ItemCubit, ItemState>(
        builder: (_, state) {
          if (state is ItemLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: caramel),
                  SizedBox(height: 16.h),
                  Text(
                    'جاري تحميل المنتجات والخدمات...',
                    style: TextStyle(color: caramel, fontSize: 14.sp),
                  ),
                ],
              ),
            );
          }

          if (state is ItemError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.r, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    'خطأ في تحميل البيانات',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => context.read<ItemCubit>().fetchByCategory(widget.category),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final allItems = state is ItemLoaded ? state.items : <ItemModel>[];

          if (allItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64.r,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'لا يوجد عناصر في هذا التصنيف بعد',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: cacao,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'كن أول من يضيف منتج أو خدمة',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final filtered = allItems.where((it) => _matchesQuery(it, _query)).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ItemCubit>().fetchByCategory(widget.category);
            },
            color: caramel,
            child: filtered.isEmpty
                ? ListView(
              children: [
                SizedBox(height: 60.h),
                Icon(Icons.search_off, size: 64.r, color: Colors.grey.shade400),
                SizedBox(height: 12.h),
                Center(
                  child: Text(
                    'لا توجد نتائج لبحث: "$_query"',
                    style: TextStyle(fontSize: 14.sp, color: cacao),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: Text(
                    'جرّب كلمات أقل أو مختلفة.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                  ),
                ),
              ],
            )
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (_, i) => _ItemTile(
                item: filtered[i],
                isOwner: filtered[i].mechanicId == uid,
              ),
            ),
          );
        },
      ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton(
        backgroundColor: caramel,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddItemPage(category: widget.category)),
        ).then((_) {
          // إعادة تحميل البيانات بعد العودة
          context.read<ItemCubit>().fetchByCategory(widget.category);
        }),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final VoidCallback? onClear;

  const _SearchField({
    required this.controller,
    this.hint,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: caramel.withOpacity(.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint ?? 'ابحث...',
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClear,
          )
              : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ItemModel item;
  final bool isOwner;
  const _ItemTile({required this.item, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: caramel.withOpacity(.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.images.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                    child: CarouselSlider.builder(
                      itemCount: item.images.length,
                      itemBuilder: (_, idx, __) => Image.network(
                        item.images[idx],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            item.isService ? Icons.build : Icons.inventory_2,
                            color: Colors.grey,
                            size: 32.r,
                          ),
                        ),
                      ),
                      options: CarouselOptions(height: 140.h, viewportFraction: 1),
                    ),
                  ),
                  // علامة النوع
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: item.isService ? Colors.blue : Colors.green,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        item.isService ? 'خدمة' : 'منتج',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // علامة جديد
                  if (item.isNew)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'جديد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // عدد الصور
                  if (item.hasMultipleImages)
                    Positioned(
                      bottom: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library, color: Colors.white, size: 12.r),
                            SizedBox(width: 2.w),
                            Text(
                              '${item.imageCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: cacao,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.description?.isNotEmpty ?? false)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(
                              item.shortDescription,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: cacao.withOpacity(.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        SizedBox(height: 4.h),
                        Text(
                          item.formattedCreatedDate,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item.price != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.h,
                            horizontal: 8.w,
                          ),
                          decoration: BoxDecoration(
                            color: caramel.withOpacity(.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            item.formattedPrice,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: caramel,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      if (isOwner) ...[
                        SizedBox(height: 4.h),
                        _ownerMenu(context),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ownerMenu(BuildContext context) => PopupMenuButton<String>(
    icon: Icon(Icons.more_vert, color: cacao.withOpacity(.7), size: 18.r),
    onSelected: (v) async {
      final cubit = context.read<ItemCubit>();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      switch (v) {
        case 'edit':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditItemPage(item: item)),
          ).then((_) {
            cubit.fetchByCategory(item.category);
          });
          break;
        case 'delete':
          _showDeleteDialog(context, cubit, uid);
          break;
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 16),
            SizedBox(width: 8),
            Text('تعديل'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 16, color: Colors.red),
            SizedBox(width: 8),
            Text('حذف', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ],
  );

  void _showDeleteDialog(BuildContext context, ItemCubit cubit, String uid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العنصر'),
        content: Text('هل أنت متأكد من حذف "${item.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              cubit.deleteItem(item, uid); // تم تصحيح اسم الدالة
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
