// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sneakers_app/theme/custom_app_theme.dart';
import 'package:sneakers_app/view/product_list_screen.dart';

import '../../../utils/constants.dart';

PreferredSize? customAppBar(BuildContext context) {
  return PreferredSize(
    preferredSize: Size.fromHeight(70),
    child: AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text('Discover', style: AppThemes.homeAppBar),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: IconButton(
            // FIX: navigate đến ProductListScreen có search filter
            icon: FaIcon(
              CupertinoIcons.search,
              color: AppConstantsColor.darkTextColor,
              size: 25,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductListScreen()),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0, right: 4),
          child: IconButton(
            icon: FaIcon(
              CupertinoIcons.bell,
              color: AppConstantsColor.darkTextColor,
              size: 25,
            ),
            // Notification chưa có backend — giữ placeholder
            onPressed: () {},
          ),
        ),
      ],
    ),
  );
}