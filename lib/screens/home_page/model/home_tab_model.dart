class HomeTabResponse {
  final bool success;
  final String message;
  final List<HomeTabItem> data;

  HomeTabResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory HomeTabResponse.fromJson(Map<String, dynamic> json) {
    return HomeTabResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is List
          ? (json['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => HomeTabItem.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class HomeTabItem {
  final int? id;
  final String title;
  final String? slug;
  final int? sortOrder;
  final bool isDefault;
  final bool isActive;
  final bool showOnApp;
  final bool showOnWeb;
  final List<String> platforms;
  final Map<String, dynamic> layoutQuery;
  final HomeTabAppearance? appearance;
  final List<String> searchLabels;
  final String? icon;
  final String? activeIcon;
  final String? backgroundImage;

  HomeTabItem({
    this.id,
    required this.title,
    this.slug,
    this.sortOrder,
    this.isDefault = false,
    this.isActive = true,
    this.showOnApp = true,
    this.showOnWeb = true,
    this.platforms = const [],
    this.layoutQuery = const {},
    this.appearance,
    this.searchLabels = const [],
    this.icon,
    this.activeIcon,
    this.backgroundImage,
  });

  factory HomeTabItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedLayoutQuery = {};
    if (json['layout_query'] is Map) {
      parsedLayoutQuery = Map<String, dynamic>.from(json['layout_query'] as Map);
    }

    HomeTabAppearance? parsedAppearance;
    if (json['appearance'] != null && json['appearance'] is Map) {
      parsedAppearance = HomeTabAppearance.fromJson(
        json['appearance'] as Map<String, dynamic>,
      );
    } else if (json['home_appearance'] != null &&
        json['home_appearance'] is Map &&
        json['home_appearance']['app'] != null &&
        json['home_appearance']['app'] is Map) {
      parsedAppearance = HomeTabAppearance.fromJson(
        json['home_appearance']['app'] as Map<String, dynamic>,
      );
    }

    return HomeTabItem(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      sortOrder: json['sort_order'] != null
          ? int.tryParse(json['sort_order'].toString())
          : null,
      isDefault: json['is_default'] == true,
      isActive: json['is_active'] != false,
      showOnApp: json['show_on_app'] != false,
      showOnWeb: json['show_on_web'] != false,
      platforms: json['platforms'] != null && json['platforms'] is List
          ? List<String>.from(json['platforms'].map((e) => e.toString()))
          : [],
      layoutQuery: parsedLayoutQuery,
      appearance: parsedAppearance,
      searchLabels: json['search_labels'] != null && json['search_labels'] is List
          ? List<String>.from(json['search_labels'].map((e) => e.toString()))
          : [],
      icon: json['icon']?.toString(),
      activeIcon: json['active_icon']?.toString(),
      backgroundImage: json['background_image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'sort_order': sortOrder,
      'is_default': isDefault,
      'is_active': isActive,
      'show_on_app': showOnApp,
      'show_on_web': showOnWeb,
      'platforms': platforms,
      'layout_query': layoutQuery,
      'appearance': appearance?.toJson(),
      'search_labels': searchLabels,
      'icon': icon,
      'active_icon': activeIcon,
      'background_image': backgroundImage,
    };
  }
}

class HomeTabAppearance {
  final String backgroundType;
  final String? gradientStart;
  final String? gradientEnd;
  final String? gradientAngle;
  final String? fontColor;
  final String? activeFontColor;
  final String? icon;
  final String? activeIcon;
  final String? backgroundImage;
  final String? mobileBackgroundImage;
  final String? tabletBackgroundImage;

  HomeTabAppearance({
    this.backgroundType = '',
    this.gradientStart,
    this.gradientEnd,
    this.gradientAngle,
    this.fontColor,
    this.activeFontColor,
    this.icon,
    this.activeIcon,
    this.backgroundImage,
    this.mobileBackgroundImage,
    this.tabletBackgroundImage,
  });

  factory HomeTabAppearance.fromJson(Map<String, dynamic> json) {
    return HomeTabAppearance(
      backgroundType: json['background_type']?.toString() ?? '',
      gradientStart: json['gradient_start']?.toString(),
      gradientEnd: json['gradient_end']?.toString(),
      gradientAngle: json['gradient_angle']?.toString(),
      fontColor: json['font_color']?.toString(),
      activeFontColor: json['active_font_color']?.toString(),
      icon: json['icon']?.toString(),
      activeIcon: json['active_icon']?.toString(),
      backgroundImage: json['background_image']?.toString(),
      mobileBackgroundImage: json['mobile_background_image']?.toString(),
      tabletBackgroundImage: json['tablet_background_image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'background_type': backgroundType,
      'gradient_start': gradientStart,
      'gradient_end': gradientEnd,
      'gradient_angle': gradientAngle,
      'font_color': fontColor,
      'active_font_color': activeFontColor,
      'icon': icon,
      'active_icon': activeIcon,
      'background_image': backgroundImage,
      'mobile_background_image': mobileBackgroundImage,
      'tablet_background_image': tabletBackgroundImage,
    };
  }
}
