import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../animation/fadeanimation.dart';
import '../../../data/dummy_data.dart';
import '../../../models/shoe_model.dart';
import '../../../services/api_service.dart';
import '../../../theme/custom_app_theme.dart';
import '../../../utils/constants.dart';
import '../../detail/detail_screen.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  int selectedIndexOfCategory = 0;
  int selectedIndexOfFeatured = 0;
  bool _isLoading = true;
  List<ShoeModel> availableShoes = [];

  @override
  void initState() {
    super.initState();
    _loadShoes();
  }

  Future<void> _loadShoes() async {
    try {
      final shoes = await ApiService.getShoes(
        brand: selectedIndexOfCategory == 0 ? null : categories[selectedIndexOfCategory],
      );
      if (!mounted) {
        return;
      }
      setState(() {
        availableShoes = shoes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load products from API.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _topCategoriesWidget(width, height),
        const SizedBox(height: 10),
        Expanded(
          child: availableShoes.isEmpty
              ? const Center(child: Text('No products found.'))
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _featuredSection(width, height),
                    _moreTextWidget(),
                    _gridSection(width, height),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _topCategoriesWidget(double width, double height) {
    return SizedBox(
      width: width,
      height: height / 18,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndexOfCategory = index;
                _isLoading = true;
              });
              _loadShoes();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                categories[index],
                style: TextStyle(
                  fontSize: selectedIndexOfCategory == index ? 21 : 18,
                  color: selectedIndexOfCategory == index
                      ? AppConstantsColor.darkTextColor
                      : AppConstantsColor.unSelectedTextColor,
                  fontWeight: selectedIndexOfCategory == index ? FontWeight.bold : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _featuredSection(double width, double height) {
    return SizedBox(
      height: height / 2.5,
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            width: width / 16,
            child: RotatedBox(
              quarterTurns: -1,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: featured.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedIndexOfFeatured = index);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        featured[index],
                        style: TextStyle(
                          fontSize: selectedIndexOfFeatured == index ? 19 : 17,
                          color: selectedIndexOfFeatured == index
                              ? AppConstantsColor.darkTextColor
                              : AppConstantsColor.unSelectedTextColor,
                          fontWeight: selectedIndexOfFeatured == index ? FontWeight.bold : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: availableShoes.length,
              itemBuilder: (ctx, index) {
                final shoe = availableShoes[index];
                return GestureDetector(
                  onTap: () => _openDetails(shoe),
                  child: Container(
                    margin: const EdgeInsets.all(15),
                    width: width / 1.5,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: shoe.modelColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 16,
                          right: 8,
                          child: FadeAnimation(
                            delay: 0.5,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    shoe.brand,
                                    style: AppThemes.homeProductName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 54,
                          left: 16,
                          right: 16,
                          child: FadeAnimation(
                            delay: 0.8,
                            child: Text(
                              shoe.name,
                              style: AppThemes.homeProductModel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 110,
                          left: 16,
                          child: FadeAnimation(
                            delay: 1,
                            child: Text(
                              '\$${shoe.price.toStringAsFixed(2)}',
                              style: AppThemes.homeProductPrice,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 20,
                          child: FadeAnimation(
                            delay: 1.2,
                            child: Hero(
                              tag: shoe.imgAddress,
                              child: SizedBox(
                                height: 130,
                                child: Image.network(
                                  shoe.imgAddress,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, size: 72, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 10,
                          child: IconButton(
                            onPressed: () => _openDetails(shoe),
                            icon: const Icon(Icons.arrow_circle_right_outlined, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreTextWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        children: [
          Text('More', style: AppThemes.homeMoreText),
          Spacer(),
          IconButton(
            onPressed: null,
            icon: Icon(CupertinoIcons.arrow_right, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _gridSection(double width, double height) {
    return SizedBox(
      height: height / 3.1,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: availableShoes.length,
        itemBuilder: (ctx, index) {
          final shoe = availableShoes[index];
          return GestureDetector(
            onTap: () => _openDetails(shoe),
            child: Container(
              margin: const EdgeInsets.all(10),
              width: width / 2.24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: Container(
                      width: width / 13,
                      height: height / 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: const RotatedBox(
                        quarterTurns: -1,
                        child: Center(child: Text('NEW', style: AppThemes.homeGridNewText)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border),
                    ),
                  ),
                  Positioned(
                    top: 34,
                    left: 24,
                    right: 24,
                    child: FadeAnimation(
                      delay: 0.6,
                      child: SizedBox(
                        height: height / 9,
                        child: Hero(
                          tag: '${shoe.imgAddress}-grid',
                          child: Image.network(
                            shoe.imgAddress,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, size: 60),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 44,
                    child: Text(
                      '${shoe.brand} ${shoe.name}',
                      style: AppThemes.homeGridNameAndModel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 18,
                    child: Text(
                      '\$${shoe.price.toStringAsFixed(2)}',
                      style: AppThemes.homeGridPrice,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDetails(ShoeModel shoe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => DetailScreen(shoe: shoe)),
    );
  }
}
