import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/constant.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';

import '../../policies/view/app_policies_page.dart';

class TrustSectionWidget extends StatelessWidget {
  const TrustSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              genuineProducts(),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: dot(),
              ),
              contactLessDelivery(),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: dot(),
              ),
              securePayment(),
            ],
          ),
          const SizedBox(height: 20,),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                const TextSpan(
                  text: 'By placing the order, you agree to ',
                ),
                TextSpan(
                  text: "${AppConstant.appName}'s ",
                ),
                TextSpan(
                  text: 'Terms of Use',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      GoRouter.of(context).push(
                        AppRoutes.policyPage,
                        extra: {'policy-type': PolicyType.termsAndConditions}
                      );
                    },
                ),
                const TextSpan(
                  text: ' and ',
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      GoRouter.of(context).push(
                          AppRoutes.policyPage,
                          extra: {'policy-type': PolicyType.privacyPolicy}
                      );
                    },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget genuineProducts () {
    return Column(
      children: [
        const CustomImageContainer(
          imagePath: 'assets/images/icons/genuine-products.png',
          height: 40,
        ),
        Text(
          'Genuine Products',
          style: AppTextStyles.caption.copyWith(
            color: Colors.grey.shade600
          ),
        )
      ],
    );
  }
  Widget contactLessDelivery () {
    return Column(
      children: [
        const CustomImageContainer(
            imagePath: 'assets/images/icons/contactless-delivery.png',
          height: 40,
        ),
        Text(
          'Contactless Delivery',
          style: AppTextStyles.caption.copyWith(
              color: Colors.grey.shade600
          ),
        )
      ],
    );
  }
  Widget securePayment () {
    return Column(
      children: [
        const CustomImageContainer(
            imagePath: 'assets/images/icons/secure-payments.png',
          height: 40,
        ),
        Text(
          'Secure Payment',
          style: AppTextStyles.caption.copyWith(
              color: Colors.grey.shade600
          ),
        )
      ],
    );
  }

  Widget dot() {
    return Container(
      height: 4,
      width: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        shape: BoxShape.circle,
      ),
    );
  }

}
