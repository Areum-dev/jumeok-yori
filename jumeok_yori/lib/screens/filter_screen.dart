import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recommendation_filter.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_slider_card.dart';
import '../widgets/option_chip.dart';
import '../widgets/primary_button.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late RecommendationFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = context.read<AppState>().filter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('조건 정하기')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                children: [
                  FilterSliderCard(
                    label: '거리',
                    valueText: '${_filter.distanceLabel} 이내',
                    value: _filter.distanceKm,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(distanceKm: v),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilterSliderCard(
                    label: '최대 가격',
                    valueText: _filter.priceLabel,
                    value: _filter.maxPrice.toDouble(),
                    min: 5000,
                    max: 30000,
                    divisions: 25,
                    onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(maxPrice: v.round()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('카테고리'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kCategoryOptions.map((c) {
                      final selected = _filter.categoryLabel == c;
                      return OptionChip(
                        label: c,
                        selected: selected,
                        onTap: () => setState(() {
                          _filter = _filter.copyWith(
                            category: c == '전체' ? null : c,
                          );
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('옵션'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OptionChip(
                        label: '혼밥',
                        icon: Icons.person_outline_rounded,
                        selected: _filter.soloFriendly,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            soloFriendly: !_filter.soloFriendly,
                          ),
                        ),
                      ),
                      OptionChip(
                        label: '포장',
                        icon: Icons.takeout_dining_outlined,
                        selected: _filter.takeoutAvailable,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            takeoutAvailable: !_filter.takeoutAvailable,
                          ),
                        ),
                      ),
                      OptionChip(
                        label: '배달',
                        icon: Icons.delivery_dining_outlined,
                        selected: _filter.deliveryAvailable,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            deliveryAvailable: !_filter.deliveryAvailable,
                          ),
                        ),
                      ),
                      OptionChip(
                        label: '비건',
                        icon: Icons.eco_outlined,
                        selected: _filter.veganOption,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            veganOption: !_filter.veganOption,
                          ),
                        ),
                      ),
                      OptionChip(
                        label: '최근 제외',
                        icon: Icons.history_rounded,
                        selected: _filter.excludeRecent,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            excludeRecent: !_filter.excludeRecent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: '이 조건으로 추천받기',
                onPressed: () {
                  context.read<AppState>().updateFilter(_filter);
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/draw-loading');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.darkInk,
    ),
  );
}
