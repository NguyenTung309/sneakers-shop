import 'package:flutter/material.dart';

class ShoeModel {
  int? id;
  String name;
  String brand;
  String description;
  double price;
  String imgAddress;
  List<ProductVariant>? variants;
  List<Review>? reviews;

  ShoeModel({
    this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.price,
    required this.imgAddress,
    this.variants,
    this.reviews,
  });

  factory ShoeModel.fromJson(Map<String, dynamic> json) {
    return ShoeModel(
      id: json['id'] as int?,
      name: (json['name'] ?? '') as String,
      brand: (json['brand'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imgAddress: (json['imageUrl'] ?? '') as String,
      variants: (json['variants'] as List<dynamic>?)
          ?.map((variant) => ProductVariant.fromJson(variant as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((review) => Review.fromJson(review as Map<String, dynamic>))
          .toList(),
    );
  }

  String get model => name;

  Color get modelColor {
    final palette = <Color>[
      const Color(0xFFE57373),
      const Color(0xFF64B5F6),
      const Color(0xFF81C784),
      const Color(0xFFFFB74D),
      const Color(0xFFBA68C8),
      const Color(0xFF4DB6AC),
    ];
    final seed = (brand + name).codeUnits.fold<int>(0, (sum, value) => sum + value);
    return palette[seed % palette.length];
  }
}

class ProductVariant {
  int id;
  String size;
  String color;
  int stock;

  ProductVariant({
    required this.id,
    required this.size,
    required this.color,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int? ?? 0,
      size: (json['size'] ?? '') as String,
      color: (json['color'] ?? '') as String,
      stock: json['stock'] as int? ?? 0,
    );
  }
}

class Review {
  int id;
  int rating;
  String comment;
  String userName;
  DateTime createdAt;

  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int? ?? 0,
      rating: json['rating'] as int? ?? 0,
      comment: (json['comment'] ?? '') as String,
      userName: (json['userName'] ?? 'Anonymous') as String,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '') as String) ?? DateTime.now(),
    );
  }
}
