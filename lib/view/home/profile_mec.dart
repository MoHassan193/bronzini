// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../model/utils/show.dart';

/* لوحة الألوان */
const caramel = Color(0xFFC68B59);
const ivory   = Color(0xFFFFF7EE);
const cacao   = Color(0xFF4E342E);

class EditMechanicProfileScreen extends StatefulWidget {
  const EditMechanicProfileScreen({super.key});

  @override
  State<EditMechanicProfileScreen> createState() =>
      _EditMechanicProfileScreenState();
}

class _EditMechanicProfileScreenState extends State<EditMechanicProfileScreen> {
  final _form  = GlobalKey<FormState>();
  final _name  = TextEditingController();
  final _phone = TextEditingController();
  final _addr  = TextEditingController();
  final _about = TextEditingController();

  final uid = FirebaseAuth.instance.currentUser!.uid;
  bool _loading = true;
  bool _uploadingPhoto = false;

  String email = '';
  String userRole = '';          // قيمته في الداتابيز: 'workshop' أو 'mechanic'
  String? _photoUrl;             // URL الحالية المحفوظة
  File? _localPickedImageFile;   // لو المستخدم اختار صورة محليًا

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // تحويل قيمة role إلى نص عربي للعرض
  String _roleLabel(String role) {
    return role == 'workshop' ? 'ورشه متخصصه' : 'صاحب محل قطع غيار';
  }

  // عناوين عربي حسب الدور
  String get _titleText =>
      userRole == 'workshop' ? 'تعديل ملف ورشه متخصصه' : 'تعديل ملف صاحب محل قطع غيار';

  String get _infoTitle =>
      'معلومات ${_roleLabel(userRole)}';

  String get _nameHint =>
      userRole == 'workshop' ? 'اسم ورشه متخصصه' : 'اسم صاحب محل قطع غيار';

  String get _aboutHint =>
      userRole == 'workshop'
          ? 'نبذة عن خدمات الورشة (اختياري)'
          : 'نبذة عن نشاط المحل وخدماته (اختياري)';

  Future<void> _fetchData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final d = doc.data() ?? {};
        _name.text   = d['name']     ?? '';
        _phone.text  = d['phone']    ?? '';
        _addr.text   = d['address']  ?? '';
        _about.text  = d['about']    ?? '';
        email        = d['email']    ?? '';
        userRole     = d['role']     ?? ''; // 'workshop' أو 'mechanic'
        _photoUrl    = d['photoUrl'] ?? null;
      }
      setState(() => _loading = false);
    } catch (e) {
      Show.mo('خطأ في جلب البيانات: $e', Colors.red);
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: Text(_titleText),
        backgroundColor: caramel,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_photoUrl != null && _photoUrl!.isNotEmpty)
            IconButton(
              tooltip: 'إزالة الصورة',
              onPressed: _uploadingPhoto ? null : _removePhoto,
              icon: const Icon(Icons.delete_outline, color: Colors.white),
            ),
        ],
      ),
      body: _loading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: caramel),
            SizedBox(height: 16.h),
            Text(
              'جاري تحميل البيانات...',
              style: TextStyle(color: caramel, fontSize: 14.sp),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          /* خلفية متدرّجة خفيفة */
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [ivory, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          /* محتوى قابل للتمرير */
          SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                /* صورة + إيميل + نوع الحساب + زر تغيير النوع */
                _buildHeader(),
                SizedBox(height: 20.h),

                /* بطاقة البيانات */
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r)),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Form(
                      key: _form,
                      child: Column(
                        children: [
                          Text(
                            _infoTitle,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: cacao,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          _field(
                            controller: _name,
                            hint: _nameHint,
                            prefix: Icons.person,
                          ),
                          SizedBox(height: 14.h),

                          _field(
                            controller: _phone,
                            hint: 'رقم الهاتف',
                            keyboard: TextInputType.phone,
                            prefix: Icons.phone,
                            suffix: IconButton(
                              icon: Icon(Icons.copy, size: 18.r),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _phone.text));
                                Show.mo('تم نسخ الرقم', caramel);
                              },
                            ),
                          ),
                          SizedBox(height: 14.h),

                          _field(
                            controller: _addr,
                            hint: 'العنوان بالتفصيل',
                            prefix: Icons.location_on,
                            maxLines: 2,
                            suffix: IconButton(
                              icon: Icon(Icons.copy, size: 18.r),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _addr.text));
                                Show.mo('تم نسخ العنوان', caramel);
                              },
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Text(
                                'مثال: طرابلس - منطقة السراج - شارع الجامعة',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: cacao.withOpacity(.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 14.h),

                          _field(
                            controller: _about,
                            hint: _aboutHint,
                            prefix: Icons.info_outline,
                            maxLines: 3,
                            required: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 80.h), // مساحة لزر الحفظ العائم
              ],
            ),
          ),

          /* زر الحفظ العائم */
          Positioned(
            left: 20.w,
            right: 20.w,
            bottom: 20.h,
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                gradient: LinearGradient(
                  colors: [caramel, caramel.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: caramel.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: _uploadingPhoto
                    ? SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Icon(Icons.save, color: Colors.white, size: 20.r),
                label: Text(
                  'حفظ التغييرات',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: _uploadingPhoto ? null : _save,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*──────── رأس الصفحة (Avatar + Email + نوع الحساب + زر تغيير الصورة + زر تبديل النوع) ────────*/
  Widget _buildHeader() {
    final avatarSize = 100.w;

    ImageProvider? avatarProvider;
    if (_localPickedImageFile != null) {
      avatarProvider = FileImage(_localPickedImageFile!);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      avatarProvider = NetworkImage(_photoUrl!);
    }

    final isWorkshop = userRole == 'workshop';

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [caramel, caramel.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(50.r),
                boxShadow: [
                  BoxShadow(
                    color: caramel.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(47.r),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(47.r),
                  child: avatarProvider != null
                      ? Image(
                    image: avatarProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(),
                  )
                      : _avatarFallback(),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: caramel,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: caramel.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'اختيار من المعرض',
                      onPressed: _uploadingPhoto ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                    ),
                    IconButton(
                      tooltip: 'التقاط بالكاميرا',
                      onPressed: _uploadingPhoto ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          email,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: cacao,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: caramel.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            _roleLabel(userRole), // ورشه متخصصه | صاحب محل قطع غيار
            style: TextStyle(
              fontSize: 12.sp,
              color: caramel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 10.h),

        // زر تبديل نوع الحساب
        ElevatedButton.icon(
          onPressed: _uploadingPhoto ? null : _toggleRole,
          style: ElevatedButton.styleFrom(
            backgroundColor: cacao,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.swap_horiz, color: Colors.white),
          label: Text(
            isWorkshop ? 'التبديل إلى صاحب محل قطع غيار'
                : 'التبديل إلى ورشه متخصصه',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    return Center(
      child: Icon(
        userRole == 'workshop' ? Icons.garage_rounded : Icons.store_mall_directory_rounded,
        color: caramel,
        size: 40.r,
      ),
    );
  }

  /*──────── اختيار الصورة ورفعها ────────*/
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024, // تقليل الحجم قبل الرفع
        imageQuality: 85,
      );
      if (picked == null) return;

      final file = File(picked.path);
      setState(() => _localPickedImageFile = file);

      await _uploadImage(file);
    } catch (e) {
      Show.mo('تعذّر اختيار الصورة: $e', Colors.red);
    }
  }

  Future<void> _uploadImage(File file) async {
    setState(() => _uploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');

      // نرفع الصورة ونعيّن نوعها
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=604800'),
      );

      final snapshot = await uploadTask.whenComplete(() => {});
      final url = await snapshot.ref.getDownloadURL();

      // نحفظ الـ URL في Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _photoUrl = url;
      });

      Show.mo('تم تحديث الصورة الشخصية ✅', Colors.green);
    } on FirebaseException catch (e) {
      Show.mo('فشل رفع الصورة: ${e.message}', Colors.red);
    } catch (e) {
      Show.mo('فشل رفع الصورة: $e', Colors.red);
    } finally {
      setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إزالة الصورة'),
        content: const Text('هل تريد إزالة الصورة الشخصية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('نعم')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      setState(() => _uploadingPhoto = true);
      // احذف من Storage (لو كانت موجودة)
      final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');
      await ref.delete().catchError((_) {}); // تجاهل لو غير موجودة

      // احذف من Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _photoUrl = null;
        _localPickedImageFile = null;
      });
      Show.mo('تمت إزالة الصورة', Colors.green);
    } catch (e) {
      Show.mo('تعذّر الإزالة: $e', Colors.red);
    } finally {
      setState(() => _uploadingPhoto = false);
    }
  }

  /*──────── تبديل نوع الحساب ────────*/
  Future<void> _toggleRole() async {
    final newRole = userRole == 'workshop' ? 'mechanic' : 'workshop';
    final newRoleLabel = _roleLabel(newRole);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد التغيير'),
        content: Text('هل تريد تغيير نوع الحساب إلى "$newRoleLabel"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('نعم')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _loading = true);

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        userRole = newRole; // تحديث محلي فوري
      });

      Show.mo('تم تغيير نوع الحساب إلى "$newRoleLabel" ✅', Colors.green);
    } catch (e) {
      Show.mo('تعذر تغيير نوع الحساب: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /*──────── عنصر إدخال موحد ────────*/
  Widget _field({
    required TextEditingController controller,
    required String hint,
    IconData? prefix,
    Widget? suffix,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: hint,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: cacao,
            ),
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontSize: 13.sp),
                ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          validator: (v) => required && v!.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: prefix != null
                ? Container(
              margin: EdgeInsets.all(8.r),
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: caramel.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(prefix, size: 16.r, color: caramel),
            )
                : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: caramel.withOpacity(.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: caramel, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
          ),
        ),
      ],
    );
  }

  /*──────── زر الحفظ ────────*/
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'address': _addr.text.trim(),
        'about': _about.text.trim(),
        // لا نحدث photoUrl هنا إلا لو اتغير عبر الرفع
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Show.mo('تم حفظ التعديلات بنجاح! ✅', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Show.mo('فشل الحفظ: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _addr.dispose();
    _about.dispose();
    super.dispose();
  }
}
