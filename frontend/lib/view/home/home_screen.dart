import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import 'components/app_bar.dart';
import 'components/body.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstantsColor.backgroundColor,
        // FIX: truyền context để app bar có thể navigate
        appBar: customAppBar(context),
        body: const Body(),
      ),
    );
  }
}