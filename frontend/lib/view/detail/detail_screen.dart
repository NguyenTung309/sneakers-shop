import 'package:flutter/material.dart';

import '../../models/shoe_model.dart';
import '../../utils/constants.dart';
import 'components/body.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.shoe});

  final ShoeModel shoe;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstantsColor.backgroundColor,
        appBar: AppBar(
          title: Text(shoe.brand),
        ),
        body: DetailsBody(shoe: shoe),
      ),
    );
  }
}
