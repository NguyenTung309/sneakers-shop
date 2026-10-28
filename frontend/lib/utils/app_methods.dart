import 'package:flutter/material.dart';

import 'package:sneakers_app/widget/snack_bar.dart';
import 'package:sneakers_app/services/api_service.dart';

import '../models/models.dart';

class AppMethods {
  AppMethods._();
  static Future<void> addToCart(ShoeModel data, BuildContext context, {int? variantId}) async {
    final resolvedVariantId = variantId ??
        ((data.variants != null && data.variants!.isNotEmpty) ? data.variants!.first.id : null);

    if (data.id == null || resolvedVariantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(failedSnackBar());
      return;
    }

    try {
      await ApiService.addToCart(data.id!, resolvedVariantId, 1);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(successSnackBar());
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(failedSnackBar());
    }
  }

  // Commented out as it's not used in API-based app
  // static double sumOfItemsOnBag() {
  //   double sumPrice = 0.0;
  //   for (ShoeModel bagModel in itemsOnBag) {
  //     sumPrice = sumPrice + bagModel.price;
  //   }
  //   return sumPrice;
  // }
}
