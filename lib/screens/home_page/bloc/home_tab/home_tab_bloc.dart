import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_commerce/screens/home_page/bloc/home_tab/home_tab_event.dart';
import 'package:hyper_commerce/screens/home_page/bloc/home_tab/home_tab_state.dart';
import 'package:hyper_commerce/screens/home_page/model/home_tab_model.dart';
import 'package:hyper_commerce/screens/home_page/repo/home_tab_repo.dart';
import '../../../../utils/widgets/cache_manager.dart';

class HomeTabBloc extends Bloc<HomeTabEvent, HomeTabState> {
  final HomeTabRepository repository = HomeTabRepository();

  HomeTabBloc() : super(HomeTabInitial()) {
    on<FetchHomeTabs>(_onFetchHomeTabs);
  }

  Future<void> _onFetchHomeTabs(
    FetchHomeTabs event,
    Emitter<HomeTabState> emit,
  ) async {
    // 1. Emit cached tabs only if state is not already loaded
    final cached = await repository.getCachedHomeTabs();
    if (cached != null && state is! HomeTabLoaded) {
      final cachedResponse = HomeTabResponse.fromJson(cached);
      if (cachedResponse.success && cachedResponse.data.isNotEmpty) {
        emit(HomeTabLoaded(
          message: cachedResponse.message,
          homeTabs: cachedResponse.data,
        ));
      }
    } else if (state is! HomeTabLoaded) {
      emit(HomeTabLoading());
    }

    // 2. Fetch fresh tabs from API
    try {
      final raw = await repository.fetchHomeTabs(platform: 'app');
      final response = HomeTabResponse.fromJson(raw);

      if (response.success) {
        for (var item in response.data) {
          final urls = [
            item.appearance?.mobileBackgroundImage,
            item.appearance?.tabletBackgroundImage,
            item.appearance?.backgroundImage,
            item.backgroundImage,
            item.appearance?.icon,
            item.icon,
            item.appearance?.activeIcon,
            item.activeIcon,
          ];
          for (var url in urls) {
            if (url != null && url.isNotEmpty && url.startsWith('http')) {
              customCacheManager.downloadFile(url);
            }
          }
        }

        emit(HomeTabLoaded(
          message: response.message,
          homeTabs: response.data,
        ));
      } else if (state is! HomeTabLoaded) {
        emit(HomeTabFailed(error: response.message));
      }
    } catch (e) {
      if (state is! HomeTabLoaded) {
        emit(HomeTabFailed(error: e.toString()));
      }
    }
  }
}
