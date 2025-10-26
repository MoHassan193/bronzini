import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../model/models/item.dart';
import '../../../../model/utils/show.dart';
import 'item_state.dart';

class ItemCubit extends Cubit<ItemState> {
  ItemCubit() : super(ItemInitial());

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool get isLoggedIn => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;

  // جلب العناصر حسب التصنيف (لجميع المستخدمين)
  Future<void> fetchByCategory(String category) async {
    emit(ItemLoading());
    try {
      final snap = await _db
          .collection('items')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      final list = snap.docs.map((d) => ItemModel.fromDoc(d.id, d.data())).toList();
      emit(ItemLoaded(list));
    } catch (e) {
      emit(ItemError('خطأ في جلب البيانات: ${e.toString()}'));
    }
  }

  // جلب منتجات/خدمات المستخدم الحالي فقط
  Future<void> fetchMyItems(String uid) async {
    if (!isLoggedIn) {
      emit(ItemError('يجب تسجيل الدخول أولاً'));
      return;
    }

    emit(ItemLoading());
    try {
      // تحديد نوع العناصر بناء على نوع المستخدم
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        emit(ItemError('لم يتم العثور على بيانات المستخدم'));
        return;
      }

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String;
      final itemType = userRole == 'workshop' ? 'product' : 'service';

      final snap = await _db
          .collection('items')
          .where('mechanicId', isEqualTo: uid)
          .where('type', isEqualTo: itemType)
          .orderBy('createdAt', descending: true)
          .get();

      final list = snap.docs.map((d) => ItemModel.fromDoc(d.id, d.data())).toList();
      emit(ItemLoaded(list));
    } catch (e) {
      emit(ItemError('خطأ في جلب منتجاتك: ${e.toString()}'));
    }
  }

  // إضافة منتج/خدمة جديدة
  Future<void> addItem(ItemModel item) async {
    if (!isLoggedIn) {
      emit(ItemError('يجب تسجيل الدخول لإضافة منتج'));
      return;
    }

    if (item.mechanicId != currentUserId) {
      emit(ItemError('خطأ في صلاحية الإضافة'));
      return;
    }

    try {
      // تحديد نوع العنصر بناء على نوع المستخدم
      final userDoc = await _db.collection('users').doc(currentUserId!).get();
      if (!userDoc.exists) {
        emit(ItemError('لم يتم العثور على بيانات المستخدم'));
        return;
      }

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String;
      final itemType = userRole == 'workshop' ? 'product' : 'service';

      final docRef = _db.collection('items').doc();
      final updatedItem = item.copyWith(
        id: docRef.id,
        type: itemType,
      );

      await docRef.set({
        ...updatedItem.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Show.mo(
        userRole == 'workshop' ? 'تم إضافة المنتج بنجاح' : 'تم إضافة الخدمة بنجاح',
        Colors.green,
      );

      await fetchByCategory(item.category);
    } catch (e) {
      emit(ItemError('فشل في الإضافة: ${e.toString()}'));
      print(e.toString());
    }
  }

  // تحديث منتج/خدمة موجودة
  Future<void> updateItem(ItemModel item) async {
    if (!isLoggedIn) {
      emit(ItemError('يجب تسجيل الدخول للتعديل'));
      return;
    }

    if (item.mechanicId != currentUserId) {
      emit(ItemError('لا تملك صلاحية تعديل هذا العنصر'));
      return;
    }

    try {
      await _db.collection('items').doc(item.id).update({
        ...item.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Show.mo('تم التحديث بنجاح', Colors.green);
      await fetchByCategory(item.category);
    } catch (e) {
      emit(ItemError('فشل في التحديث: ${e.toString()}'));
    }
  }

  // حذف منتج/خدمة
  Future<void> deleteItem(ItemModel item, String currentUid) async {
    if (!isLoggedIn) {
      emit(ItemError('يجب تسجيل الدخول للحذف'));
      return;
    }

    if (item.mechanicId != currentUid) {
      emit(ItemError('لا تملك صلاحية حذف هذا العنصر'));
      return;
    }

    try {
      await _db.collection('items').doc(item.id).delete();

      Show.mo('تم الحذف', Colors.orange);
      await fetchByCategory(item.category);
    } catch (e) {
      emit(ItemError('فشل في الحذف: ${e.toString()}'));
    }
  }

  // البحث في المنتجات/الخدمات
  Future<void> searchItems(String query, {String? category}) async {
    if (query.isEmpty) {
      if (category != null) {
        await fetchByCategory(category);
      }
      return;
    }

    emit(ItemLoading());
    try {
      Query baseQuery = _db.collection('items');

      if (category != null) {
        baseQuery = baseQuery.where('category', isEqualTo: category);
      }

      final snap = await baseQuery
          .orderBy('createdAt', descending: true)
          .get();

      final list = snap.docs
          .map((d) => ItemModel.fromDoc(d.id, d.data() as Map<String, dynamic>))
          .where((item) =>
      item.name.toLowerCase().contains(query.toLowerCase()) ||
          (item.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();

      emit(ItemLoaded(list));
    } catch (e) {
      emit(ItemError('خطأ في البحث: ${e.toString()}'));
    }
  }

  // جلب منتجات/خدمات مستخدم معين (للمشاهدة فقط)
  Future<void> fetchUserItems(String userId) async {
    emit(ItemLoading());
    try {
      // تحديد نوع العناصر بناء على نوع المستخدم
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        emit(ItemError('لم يتم العثور على بيانات المستخدم'));
        return;
      }

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String;
      final itemType = userRole == 'workshop' ? 'product' : 'service';

      final snap = await _db
          .collection('items')
          .where('mechanicId', isEqualTo: userId)
          .where('type', isEqualTo: itemType)
          .orderBy('createdAt', descending: true)
          .get();

      final list = snap.docs.map((d) => ItemModel.fromDoc(d.id, d.data())).toList();
      emit(ItemLoaded(list));
    } catch (e) {
      emit(ItemError('خطأ في جلب منتجات المستخدم: ${e.toString()}'));
    }
  }

  // التحقق من صلاحية المستخدم للعنصر
  bool canUserEditItem(ItemModel item) {
    return isLoggedIn && item.mechanicId == currentUserId;
  }

  // دالة مساعدة للحصول على معلومات المستخدم
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }
}