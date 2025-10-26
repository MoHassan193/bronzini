import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String name;
  final String? description;
  final double? price;
  final String category;
  final String mechanicId;
  final List<String> images;
  final String type; // 'product' للمنتجات أو 'service' للخدمات
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ItemModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    required this.category,
    required this.mechanicId,
    required this.images,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  // إنشاء ItemModel من بيانات Firestore
  factory ItemModel.fromDoc(String docId, Map<String, dynamic> data) {
    return ItemModel(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'],
      price: data['price']?.toDouble(),
      category: data['category'] ?? '',
      mechanicId: data['mechanicId'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      type: data['type'] ?? 'product',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // تحويل ItemModel إلى Map للحفظ في Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'mechanicId': mechanicId,
      'images': images,
      'type': type,
    };
  }

  // تحويل ItemModel إلى Map كامل
  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'mechanicId': mechanicId,
      'images': images,
      'type': type,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // إنشاء نسخة معدلة
  ItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? mechanicId,
    List<String>? images,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      mechanicId: mechanicId ?? this.mechanicId,
      images: images ?? this.images,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // التحقق من صحة البيانات
  bool get isValid {
    return name.isNotEmpty &&
        category.isNotEmpty &&
        mechanicId.isNotEmpty &&
        images.isNotEmpty &&
        type.isNotEmpty;
  }

  // الحصول على الصورة الأولى
  String? get primaryImageUrl {
    return images.isNotEmpty ? images.first : null;
  }

  // تنسيق السعر للعرض
  String get formattedPrice {
    if (price == null) return 'غير محدد';
    return '${price!.toStringAsFixed(price! % 1 == 0 ? 0 : 2)} د.ل';
  }

  // تنسيق تاريخ الإنشاء
  String get formattedCreatedDate {
    if (createdAt == null) return 'غير محدد';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  // فحص إذا كان المنتج جديد
  bool get isNew {
    if (createdAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    return difference.inHours < 24;
  }

  // فحص إذا كان منتج أم خدمة
  bool get isProduct => type == 'product';
  bool get isService => type == 'service';

  // الحصول على نص وصفي قصير
  String get shortDescription {
    if (description == null || description!.isEmpty) {
      return 'لا يوجد وصف';
    }
    if (description!.length <= 50) {
      return description!;
    }
    return '${description!.substring(0, 50)}...';
  }

  // فحص الصور المتعددة
  bool get hasMultipleImages => images.length > 1;
  int get imageCount => images.length;

  @override
  String toString() {
    return 'ItemModel(id: $id, name: $name, category: $category, type: $type, mechanicId: $mechanicId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}