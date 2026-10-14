import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/screens/home_page/bloc/home_layout/home_layout_bloc.dart';
import 'package:hyper_commerce/screens/home_page/bloc/home_layout/home_layout_state.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_commerce/utils/widgets/empty_states_page.dart';

import 'home_layout_body.dart';

class HomeTabContent extends StatefulWidget {
  final int tabIndex;
  final Map<String, dynamic>? layoutQuery;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;

  const HomeTabContent({
    super.key,
    this.tabIndex = 0,
    this.layoutQuery,
    required this.onRefresh,
    required this.onRetry,
  });

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isQueryMatching(Map<String, dynamic>? stateQuery, Map<String, dynamic>? tabQuery) {
    if (widget.tabIndex == 0) {
      // Index 0 is the default global layout (stateQuery is null or empty)
      return stateQuery == null || stateQuery.isEmpty;
    }
    if (stateQuery == null && tabQuery == null) return true;
    if (stateQuery == null || tabQuery == null) return false;
    if (stateQuery.length != tabQuery.length) return false;
    for (final key in stateQuery.keys) {
      if (stateQuery[key]?.toString() != tabQuery[key]?.toString()) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<HomeLayoutBloc, HomeLayoutState>(
      buildWhen: (previous, current) {
        return previous != current;
      },
      builder: (context, state) {
        if (state is HomeLayoutLoaded) {
          if (!_isQueryMatching(state.layoutQuery, widget.layoutQuery)) {
            return const Center(
              child: CustomCircularProgressIndicator(),
            );
          }

          if (state.sections.isEmpty) {
            return NoProductPage(
              onRetry: widget.onRetry,
            );
          }

          return CustomRefreshIndicator(
            onRefresh: widget.onRefresh,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: 0,
                    bottom: 30.h,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < state.sections.length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 0.0),
                            child: HomeLayoutBody.buildSection(
                              context,
                              state.sections[index],
                              index,
                            ),
                          );
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: const Center(
                            child: CustomCircularProgressIndicator(),
                          ),
                        );
                      },
                      childCount: state.sections.length +
                          (state.isLoadingMore ? 1 : 0),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is HomeLayoutFailed) {
          if (!_isQueryMatching(state.layoutQuery, widget.layoutQuery)) {
            return const Center(
              child: CustomCircularProgressIndicator(),
            );
          }
          return NoProductPage(
            onRetry: widget.onRetry,
          );
        }
        return const Center(
          child: CustomCircularProgressIndicator(),
        );
      },
    );
  }
}

