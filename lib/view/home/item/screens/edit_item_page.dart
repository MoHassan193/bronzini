// ignore_for_file: use_build_context_synchronously
import 'dart:io';
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

class EditItemPage extends StatefulWidget {
  final ItemModel item;
  const EditItemPage({super.key, required this.item});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _price;

  final _picker = ImagePicker();
  late List<String> _existingUrls;   // الصور القديمة
  List<XFile> _newPicked = [];       // الصور الجديدة
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _desc = TextEditingController(text: widget.item.description ?? '');
    _price = TextEditingController(
        text: widget.item.price?.toStringAsFixed(0) ?? '');
    _existingUrls = List.from(widget.item.images);
  }

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF795548);
    const beige = Color(0xFFF8F6F0);

    // تحديد نوع العنصر
    final String itemTypeText = widget.item.isService ? 'الخدمة' : 'المنتج';

    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        title: Text('تعديل $itemTypeText'),
        backgroundColor: brown,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _form,
          child: Column(
            children: [
              // معلومات العنصر
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
                      widget.item.isService ? Icons.build_rounded : Icons.inventory_2_rounded,
                      color: brown,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تعديل $itemTypeText في تصنيف: ${widget.item.category}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            widget.item.isService ? 'خدمة' : 'منتج',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: brown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              _field(_name, 'الاسم'),
              SizedBox(height: 12.h),

              _field(_desc, 'الوصف (اختياري)',
                  maxLines: 3, required: false),
              SizedBox(height: 12.h),

              _field(_price, 'السعر (اختياري)',
                  keyboard: TextInputType.number, required: false),
              SizedBox(height: 16.h),

              /// صور موجودة
              if (_existingUrls.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('الصور الحالية',
                      style: TextStyle(
                          color: brown, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 8.h),
                _existingGrid(),
                SizedBox(height: 16.h),
              ],

              /// إضافة صور جديدة
              DottedBorder(
                color: brown,
                strokeWidth: 1.5,
                dashPattern: const [6, 3],
                borderType: BorderType.RRect,
                radius: Radius.circular(10.r),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        color: brown,
                        size: 24.r,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'إضافة صور جديدة',
                        style: TextStyle(
                          color: brown,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('اختر صور جديدة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_newPicked.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        _newGrid(),
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
                        'جاري حفظ التعديلات...',
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

              // زر الحفظ
              Container(
                width: double.infinity,
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
                    _loading ? 'جاري الحفظ...' : 'حفظ التعديلات',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctl, String hint,
      {int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
        bool required = true}) {
    const brown = Color(0xFF795548);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: hint,
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
          validator: (v) => required && v!.trim().isEmpty ? 'حقل مطلوب' : null,
          decoration: InputDecoration(
            hintText: hint,
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

  Widget _existingGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _existingUrls.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 8.h,
      crossAxisSpacing: 8.w,
    ),
    itemBuilder: (_, i) => Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.network(
            _existingUrls[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: Icon(
                widget.item.isService ? Icons.build : Icons.inventory_2,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => setState(() => _existingUrls.removeAt(i)),
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              padding: const EdgeInsets.all(4),
              child:
              const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _newGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _newPicked.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 8.h,
      crossAxisSpacing: 8.w,
    ),
    itemBuilder: (_, i) => Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.file(File(_newPicked[i].path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => setState(() => _newPicked.removeAt(i)),
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              padding: const EdgeInsets.all(4),
              child:
              const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _pickImages() async {
    try {
      final imgs = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (imgs.isNotEmpty) {
        // حساب المساحة المتاحة (الحد الأقصى 6 صور إجمالية)
        final totalExisting = _existingUrls.length + _newPicked.length;
        final remainingSlots = 6 - totalExisting;

        if (remainingSlots > 0) {
          final imagesToAdd = imgs.take(remainingSlots).toList();
          setState(() => _newPicked.addAll(imagesToAdd));

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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != widget.item.mechanicId) {
      Show.mo('لا تملك صلاحية التعديل', Colors.red);
      return;
    }

    if (_existingUrls.isEmpty && _newPicked.isEmpty) {
      Show.mo('يجب أن يحتوي العنصر على صورة واحدة على الأقل', Colors.red);
      return;
    }

    setState(() => _loading = true);
    try {
      /// رفع الصور الجديدة
      final newUrls = await Future.wait(
        _newPicked.asMap().entries.map((entry) async {
          final idx = entry.key;
          final file = File(entry.value.path);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${uid}_$idx.jpg';
          final ref = FirebaseStorage.instance.ref('items/$uid/$fileName');

          final uploadTask = ref.putFile(
            file,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'uploadedBy': uid ?? '',
                'itemCategory': widget.item.category,
              },
            ),
          );

          final snapshot = await uploadTask;
          return await snapshot.ref.getDownloadURL();
        }),
      );

      final updated = widget.item.copyWith(
        name: _name.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        price: _price.text.trim().isEmpty
            ? null
            : double.tryParse(_price.text.trim()),
        images: [..._existingUrls, ...newUrls],
      );

      await context.read<ItemCubit>().updateItem(updated);

      if (mounted) {
        final itemTypeText = widget.item.isService ? 'الخدمة' : 'المنتج';
        Show.mo('تم تعديل $itemTypeText بنجاح', Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Show.mo('خطأ: $e', Colors.red);
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