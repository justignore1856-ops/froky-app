import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_commerce/model/user_cart_model/cart_sync_action.dart';
import 'package:hyper_commerce/model/user_cart_model/user_cart.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_story_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/services/story_preload_service.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:video_player/video_player.dart';

class StoryViewerPage extends StatefulWidget {
  final List<WatchStoryGroup> storyGroups;
  final int initialGroupIndex;

  const StoryViewerPage({
    super.key,
    required this.storyGroups,
    this.initialGroupIndex = 0,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with TickerProviderStateMixin {
  late PageController _groupPageController;
  late int _currentGroupIndex;
  int _currentSlideIndex = 0;

  AnimationController? _animController;
  VideoPlayerController? _videoController;
  bool _isPaused = false;

  // Instagram-style Heavyweight Drag Down to Dismiss state
  double _dragOffsetY = 0.0;
  AnimationController? _springBackController;
  Animation<double>? _springBackAnimation;

  @override
  void initState() {
    super.initState();
    _springBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _springBackController!.addListener(() {
      if (_springBackAnimation != null) {
        setState(() {
          _dragOffsetY = _springBackAnimation!.value;
        });
      }
    });
    _springBackController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _resume();
      }
    });

    _currentGroupIndex = widget.initialGroupIndex.clamp(
      0,
      widget.storyGroups.length - 1,
    );
    _groupPageController = PageController(initialPage: _currentGroupIndex);
    _loadCurrentSlide();
  }

  void _loadCurrentSlide() {
    _animController?.dispose();
    _videoController?.pause();
    _videoController = null;

    final currentGroup = widget.storyGroups[_currentGroupIndex];
    if (currentGroup.slides.isEmpty) return;

    final slide = currentGroup.slides[_currentSlideIndex];

    // Pre-cache next upcoming slide (image or video) for zero-gap playback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentSlideIndex < currentGroup.slides.length - 1) {
        final nextSlide = currentGroup.slides[_currentSlideIndex + 1];
        StoryPreloadService().preloadSlide(context, nextSlide);
      } else if (_currentGroupIndex < widget.storyGroups.length - 1) {
        final nextGroup = widget.storyGroups[_currentGroupIndex + 1];
        if (nextGroup.slides.isNotEmpty) {
          StoryPreloadService().preloadSlide(context, nextGroup.slides.first);
        }
      }
    });

    if (slide.mediaType == StoryMediaType.video) {
      _videoController =
          StoryPreloadService().getOrCreateController(slide.mediaUrl);
      if (_videoController!.value.isInitialized) {
        _videoController!.play();
        final duration = _videoController!.value.duration.inMilliseconds > 0
            ? _videoController!.value.duration
            : slide.duration;
        _startAnimation(duration);
        setState(() {});
      } else {
        _videoController!.initialize().then((_) {
          if (!mounted) return;
          _videoController!.play();
          final duration = _videoController!.value.duration.inMilliseconds > 0
              ? _videoController!.value.duration
              : slide.duration;
          _startAnimation(duration);
          setState(() {});
        }).catchError((_) {
          _startAnimation(slide.duration);
        });
      }
    } else {
      _startAnimation(slide.duration);
    }
  }

  void _startAnimation(Duration duration) {
    _animController = AnimationController(vsync: this, duration: duration);
    _animController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onNextSlide();
      }
    });
    _animController!.forward();
    setState(() {});
  }

  void _onNextSlide() {
    final currentGroup = widget.storyGroups[_currentGroupIndex];

    if (_currentSlideIndex < currentGroup.slides.length - 1) {
      setState(() {
        _currentSlideIndex++;
      });
      _loadCurrentSlide();
    } else {
      // Mark current group as seen
      currentGroup.isSeen = true;

      // Move to next store group
      if (_currentGroupIndex < widget.storyGroups.length - 1) {
        _groupPageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      } else {
        // Last group finished, dismiss viewer
        if (mounted) {
          GoRouter.of(context).pop();
        }
      }
    }
  }

  void _onPrevSlide() {
    if (_currentSlideIndex > 0) {
      setState(() {
        _currentSlideIndex--;
      });
      _loadCurrentSlide();
    } else {
      if (_currentGroupIndex > 0) {
        _groupPageController.previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _pause() {
    if (_isPaused) return;
    _isPaused = true;
    _animController?.stop();
    _videoController?.pause();
  }

  void _resume() {
    if (!_isPaused) return;
    _isPaused = false;
    _animController?.forward();
    _videoController?.play();
  }

  // Instagram-style Damped Heavyweight Drag Handlers
  void _onVerticalDragStart(DragStartDetails details) {
    _springBackController?.stop();
    _pause();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta == null) return;
    // Progressive resistance damping for heavyweight tactile feel
    final newOffset = _dragOffsetY + (details.primaryDelta! * 0.30);
    if (newOffset >= 0) {
      setState(() {
        _dragOffsetY = newOffset.clamp(0.0, 320.0);
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffsetY > 130.0 || velocity > 650.0) {
      GoRouter.of(context).pop();
    } else {
      // Smooth elastic recoil back to full screen
      _springBackAnimation = Tween<double>(
        begin: _dragOffsetY,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _springBackController!,
          curve: Curves.easeOutCubic,
        ),
      );
      _springBackController!.forward(from: 0.0);
    }
  }

  void _onAddToCart(BuildContext context, ProductData product) {
    if (product.variants.isEmpty) return;

    if (product.variants.length > 1 ||
        product.variants.any((v) => v.addonGroups.isNotEmpty)) {
      _pause();
      /*showVariantBottomSheetWithAddons(
        variantsList: product.variants,
        productData: product,
        productImage: product.mainImage,
        quantityStepSize: product.quantityStepSize,
        context: context,
      ).then((_) => _resume());*/
    } else {
      final defaultVariant = product.variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => product.variants.first,
      );

      final item = UserCart(
        productId: product.id.toString(),
        variantId: defaultVariant.id.toString(),
        variantName: defaultVariant.title.toString(),
        vendorId: defaultVariant.storeId.toString(),
        name: product.title,
        image: product.mainImage,
        price: defaultVariant.specialPrice.toDouble(),
        originalPrice: defaultVariant.price.toDouble(),
        quantity: product.minimumOrderQuantity > 0
            ? product.minimumOrderQuantity
            : 1,
        serverCartItemId: null,
        syncAction: CartSyncAction.add,
        updatedAt: DateTime.now(),
        minQty: product.minimumOrderQuantity > 0
            ? product.minimumOrderQuantity
            : 1,
        maxQty: product.totalAllowedQuantity > 0
            ? product.totalAllowedQuantity
            : 10,
        isOutOfStock: !defaultVariant.isInStock,
        isSynced: false,
      );

      context.read<CartBloc>().add(AddToCart(item: item, context: context));
    }
  }

  @override
  void dispose() {
    _springBackController?.dispose();
    _animController?.dispose();
    _videoController?.pause();
    _videoController = null;
    _groupPageController.dispose();
    StoryPreloadService().disposeAll();
    super.dispose();
  }

  Widget _buildProgressBar(WatchStoryGroup group) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        children: List.generate(group.slides.length, (idx) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              height: 3.h,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: AnimatedBuilder(
                animation: _animController ?? const AlwaysStoppedAnimation(0.0),
                builder: (context, _) {
                  double value = 0.0;
                  if (idx < _currentSlideIndex) {
                    value = 1.0;
                  } else if (idx == _currentSlideIndex) {
                    value = _animController?.value ?? 0.0;
                  }

                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTaggedProductCard(ProductData product) {
    final defaultVariant = product.variants.isNotEmpty
        ? product.variants.firstWhere(
            (v) => v.isDefault,
            orElse: () => product.variants.first,
          )
        : null;

    final price =
        defaultVariant?.specialPrice ?? defaultVariant?.price ?? 0.0;
    final originalPrice = defaultVariant?.price ?? 0.0;
    final hasDiscount = originalPrice > price && originalPrice > 0;
    final discountPercent = hasDiscount
        ? (((originalPrice - price) / originalPrice) * 100).round()
        : 0;

    final currency = defaultVariant?.currencySymbol ?? '₹';

    return Container(
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: SizedBox(
              width: 54.w,
              height: 56.h,
              child: CustomImageContainer(
                imagePath: product.mainImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      '$currency$price',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    if (hasDiscount) ...[
                      SizedBox(width: 5.w),
                      Text(
                        '$currency$originalPrice',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '$discountPercent% off',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF267E3E),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            height: 32.h,
            child: ElevatedButton(
              onPressed: () => _onAddToCart(context, product),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2874F0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              child: Text(
                'Buy Now',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double dragProgress = (_dragOffsetY / 320.0).clamp(0.0, 1.0);
    final double curvedProgress = Curves.easeOutQuad.transform(dragProgress);
    final double scale = 1.0 - (0.30 * curvedProgress);
    final double cornerRadius = 32.r * curvedProgress;
    return CustomScaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffsetY),
          child: Transform.scale(
            scale: scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: PageView.builder(
                controller: _groupPageController,
                physics: _dragOffsetY > 0
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                itemCount: widget.storyGroups.length,
                onPageChanged: (groupIndex) {
                  setState(() {
                    _currentGroupIndex = groupIndex;
                    _currentSlideIndex = 0;
                  });
                  _loadCurrentSlide();
                },
                itemBuilder: (context, groupIndex) {
                  final group = widget.storyGroups[groupIndex];
                  if (group.slides.isEmpty) return const SizedBox.shrink();

                  final slide = group.slides[
                      _currentSlideIndex.clamp(0, group.slides.length - 1)];

                  return GestureDetector(
                    onLongPressStart: (_) => _pause(),
                    onLongPressEnd: (_) => _resume(),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Media Content (Image or Video with Hero Expansion)
                        if (slide.mediaType == StoryMediaType.video &&
                            _videoController != null &&
                            _videoController!.value.isInitialized)
                          Center(
                            child: AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                          )
                        else
                          (groupIndex == widget.initialGroupIndex &&
                                  _currentSlideIndex == 0)
                              ? Hero(
                                  tag: 'hero_story_media_${group.id}',
                                  flightShuttleBuilder: (
                                    flightContext,
                                    animation,
                                    flightDirection,
                                    fromHeroContext,
                                    toHeroContext,
                                  ) {
                                    return AnimatedBuilder(
                                      animation: animation,
                                      builder: (context, _) {
                                        final radius = (29.r *
                                                (1.0 - animation.value))
                                            .clamp(0.0, 29.r);
                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(radius),
                                          child: CustomImageContainer(
                                            imagePath: slide.mediaUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: CustomImageContainer(
                                    imagePath: slide.mediaUrl,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : CustomImageContainer(
                                  imagePath: slide.mediaUrl,
                                  fit: BoxFit.cover,
                                ),

                        // 2. Tap Touch Zones (Left 30% Prev, Right 70% Next)
                        Positioned.fill(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _onPrevSlide,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _onNextSlide,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3. Top Gradient Shadow
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 140.h,
                          child: const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 4. Bottom Gradient Shadow
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 220.h,
                          child: const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black87],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 5. Header Overlay: Progress Bars + Store Info + Close Button
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProgressBar(group),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 4.h,
                                  ),
                                  child: Row(
                                    children: [
                                      ClipOval(
                                        child: CustomImageContainer(
                                          imagePath: group.storeLogo,
                                          height: 32.r,
                                          width: 32.r,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            group.storeName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.bold,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black87,
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            slide.createdAt,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10.5.sp,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black87,
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 26.r,
                                        ),
                                        onPressed: () =>
                                            GoRouter.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 6. Bottom Shoppable Overlay (Caption + Tagged Product)
                        Positioned(
                          bottom: 24.h,
                          left: 14.w,
                          right: 14.w,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (slide.caption != null &&
                                  slide.caption!.isNotEmpty) ...[
                                Text(
                                  slide.caption!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10.h),
                              ],
                              if (slide.taggedProduct != null)
                                _buildTaggedProductCard(slide.taggedProduct!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
