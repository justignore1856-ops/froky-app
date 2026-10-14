import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import '../../../../router/app_routes.dart';
import '../../../notification_page/bloc/notification_bloc.dart';

class HomeNotificationButton extends StatelessWidget {
  final Color? iconColor;

  const HomeNotificationButton({
    super.key,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = iconColor ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      height: 30,
      width: 40,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          GoRouter.of(context).push(AppRoutes.notifications);
        },
        icon: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            int unreadCount = 0;
            if (state is NotificationLoaded) {
              unreadCount = state.unreadCount;
            }
            return Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              child: Icon(HeroiconsSolid.bell, color: effectiveColor, size: 20),
            );
          },
        ),
      ),
    );
  }
}
