import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';
import '../bloc/get_user_wishlist_bloc/get_user_wishlist_state.dart';
import '../bloc/wishlist_product_bloc/wishlist_product_bloc.dart';
import '../model/wishlist_product_model.dart';
import '../widgets/wishlist_products_grid.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    context.read<WishlistProductBloc>().add(FetchFavoriteWishlist());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScaffold(
      appBar: AppBar(
        title: Text(
          l10n?.myWishlist ?? 'My Wishlist',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<UserWishlistBloc, UserWishlistState>(
            listener: (context, state){
              if(state is UserWishlistLoaded) {
                if(state.revision > 0) {
                  context.read<WishlistProductBloc>().add(FetchFavoriteWishlist());
                }
              }
            }
          )
        ],
        child: BlocBuilder<WishlistProductBloc, WishlistProductState>(
          builder: (context, state) {

            if (state is WishlistProductLoading ||
                state is WishlistProductInitial) {
              return const CustomCircularProgressIndicator();
            }

            final List<WishlistProductItems> items = state is WishlistProductLoaded
                ? state.wishlistProductItems
                : <WishlistProductItems>[];

            return RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<WishlistProductBloc>();
                bloc.add(FetchFavoriteWishlist());
                await bloc.stream.first;
              },
              child: items.isEmpty
                  ? const _EmptyFavorites()
                  : WishlistProductsGrid(items: items),
            );
          },
        ),
      ),
    );
  }
}

/// Scrollable empty state so pull-to-refresh stays available.
class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 20),
        Center(
          child: Text(
            l10n?.yourWishlistIsEmpty ?? 'Your Wishlist is Empty',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          // TODO(i18n): add a dedicated locale key for this hint.
          child: Text(
            'Tap the heart on any product to save it here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
