// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../model/models/item.dart';
import '../../../../model/utils/show.dart';
import '../item_cubit/item_cubit.dart';

class AddItemPage extends StatefulWidget {
  final String category;
  const AddItemPage({super.key, required this.category});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _picker = ImagePicker();

  List<XFile> _picked = [];
  bool _loading = false;
  User? _currentUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    if (_currentUser == null) {
      Show.mo('يجب تسجيل الدخول أولاً', Colors.red);
      Navigator.pop(context);
      return;
    }

    // جلب بيانات المستخدم لتحديد النوع
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
      }
    } catch (e) {
      Show.mo('خطأ في جلب بيانات المستخدم', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6D4C41);
    const beige = Color(0xFFF8F6F0);

    // تحديد نوع العنصر بناء على نوع المستخدم
    final bool isWorkshop = _userData?['role'] == 'workshop';
    final String itemTypeText = isWorkshop ? 'منتج' : 'خدمة';

    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        title: Text('إضافة $itemTypeText - ${widget.category}'),
        backgroundColor: brown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _currentUser == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('يجب تسجيل الدخول أولاً'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // معلومات المستخدم
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: brown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: brown.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isWorkshop ? Icons.garage_rounded : Icons.build_rounded,
                      color: brown,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سيتم إضافة ال$itemTypeText باسم:',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _userData?['name'] ?? 'غير محدد',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: brown,
                            ),
                          ),
                          Text(
                            isWorkshop ? 'ورشة' : 'خبير صيانة سيارات',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: brown.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              _field(_name, 'اسم ال$itemTypeText', required: true),
              SizedBox(height: 12.h),

              _field(
                _desc,
                'وصف ال$itemTypeText (اختياري)',
                maxLines: 3,
                required: false,
              ),
              SizedBox(height: 12.h),

              _field(
                _price,
                'السعر بالدينار الليبي (اختياري)',
                keyboard: TextInputType.number,
                required: false,
                hint: 'مثال: 150',
              ),
              SizedBox(height: 16.h),

              /// حاوية الصور المحسنة
              DottedBorder(
                color: brown,
                strokeWidth: 2,
                dashPattern: const [8, 4],
                borderType: BorderType.RRect,
                radius: Radius.circular(12.r),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Icon(
                        _picked.isEmpty
                            ? (isWorkshop ? Icons.photo_library_outlined : Icons.photo_camera_outlined)
                            : Icons.photo_library,
                        size: 32.r,
                        color: brown,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _picked.isEmpty
                            ? 'اختر صور ال$itemTypeText'
                            : 'تم اختيار ${_picked.length} صورة',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: brown,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text(_picked.isEmpty ? 'اختر صور' : 'إضافة المزيد'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_picked.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        _previewGrid(),
                      ],
                    ],
                  ),
                ),
              ),

              if (_loading) ...[
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: brown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: 8.h),
                      Text(
                        'جاري رفع الصور وحفظ ال$itemTypeText...',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: brown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // زر الحفظ المحسن
              Container(
                height: 50.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(
                    colors: _loading
                        ? [Colors.grey, Colors.grey.shade600]
                        : [brown, brown.withOpacity(0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brown.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(
                    _loading ? Icons.hourglass_empty : Icons.save,
                    color: Colors.white,
                  ),
                  label: Text(
                    _loading ? 'جاري الحفظ...' : 'حفظ ال$itemTypeText',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctl,
      String label, {
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
        bool required = true,
        String? hint,
      }) {
    const brown = Color(0xFF6D4C41);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: brown,
            ),
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontSize: 14.sp),
                ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: ctl,
          keyboardType: keyboard,
          maxLines: maxLines,
          validator: (v) => required && v!.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: brown, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
          ),
        ),
      ],
    );
  }

  Widget _previewGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _picked.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 8.h,
      crossAxisSpacing: 8.w,
      childAspectRatio: 1,
    ),
    itemBuilder: (_, i) => Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.file(
              File(_picked[i].path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Positioned(
          top: 4.r,
          right: 4.r,
          child: GestureDetector(
            onTap: () => setState(() => _picked.removeAt(i)),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(4.r),
              child: Icon(
                Icons.close,
                size: 16.r,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4.r,
          left: 4.r,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _pickImages() async {
    try {
      final imgs = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (imgs.isNotEmpty) {
        // حد أقصى 6 صور
        final remainingSlots = 6 - _picked.length;
        if (remainingSlots > 0) {
          final imagesToAdd = imgs.take(remainingSlots).toList();
          setState(() => _picked.addAll(imagesToAdd));

          if (imgs.length > remainingSlots) {
            Show.mo('تم اختيار ${imagesToAdd.length} صور فقط (الحد الأقصى 6 صور)', Colors.orange);
          }
        } else {
          Show.mo('لا يمكن إضافة المزيد من الصور (الحد الأقصى 6 صور)', Colors.orange);
        }
      }
    } catch (e) {
      Show.mo('خطأ في اختيار الصور: $e', Colors.red);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    if (_currentUser == null) {
      Show.mo('يجب تسجيل الدخول أولاً', Colors.red);
      Navigator.pop(context);
      return;
    }

    if (_picked.isEmpty) {
      Show.mo('يجب اختيار صورة واحدة على الأقل', Colors.red);
      return;
    }

    setState(() => _loading = true);

    try {
      // رفع الصور إلى Firebase Storage
      final urls = await Future.wait(
        _picked.asMap().entries.map((entry) async {
          final idx = entry.key;
          final file = File(entry.value.path);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_currentUser!.uid}_$idx.jpg';

          final ref = FirebaseStorage.instance.ref('items/${_currentUser!.uid}/$fileName');

          final uploadTask = ref.putFile(
            file,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'uploadedBy': _currentUser!.uid,
                'itemCategory': widget.category,
              },
            ),
          );

          final snapshot = await uploadTask;
          return await snapshot.ref.getDownloadURL();
        }),
      );

      // تحديد نوع العنصر
      final itemType = _userData?['role'] == 'workshop' ? 'product' : 'service';

      // إنشاء نموذج العنصر
      final item = ItemModel(
        id: '', // سيتم تعيينه في ItemCubit
        name: _name.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        price: _price.text.trim().isEmpty ? null : double.tryParse(_price.text.trim()),
        category: widget.category,
        mechanicId: _currentUser!.uid,
        images: urls,
        type: itemType,
      );

      // حفظ العنصر باستخدام ItemCubit
      await context.read<ItemCubit>().addItem(item);

      if (mounted) {
        final itemTypeText = _userData?['role'] == 'workshop' ? 'المنتج' : 'الخدمة';
        Show.mo('تم إضافة $itemTypeText بنجاح! 🎉', Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Show.mo('خطأ: ${e.toString()}', Colors.red);
        print(e);
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }
}