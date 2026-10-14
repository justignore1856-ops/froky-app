import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart';

enum StoryMediaType { image, video }

class WatchStorySlide {
  final String id;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final Duration duration;
  final String? caption;
  final String createdAt;
  final ProductData? taggedProduct;

  WatchStorySlide({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.duration = const Duration(seconds: 5),
    this.caption,
    required this.createdAt,
    this.taggedProduct,
  });
}

class WatchStoryGroup {
  final String id;
  final String storeId;
  final String storeName;
  final String storeLogo;
  bool isSeen;
  final bool isLive;
  final List<WatchStorySlide> slides;

  WatchStoryGroup({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.storeLogo,
    this.isSeen = false,
    this.isLive = false,
    required this.slides,
  });
}

class WatchStoryMockData {
  static List<WatchStoryGroup> getDummyStories() {
    return [
      // Store 1: Carry Culture (Fashion & Ethnic Wear)
      WatchStoryGroup(
        id: 'story_1',
        storeId: 'store_101',
        storeName: 'Carry Culture',
        storeLogo:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        isSeen: false,
        isLive: true,
        slides: [
          WatchStorySlide(
            id: 'slide_1_1',
            mediaUrl:
                'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1080',
            mediaType: StoryMediaType.image,
            caption: '✨ Festive Chikankari Kurtas - Flat 65% OFF Today!',
            createdAt: '1h ago',
            taggedProduct: ProductData.fromJson({
              'id': 301,
              'title': 'Indo Era Embroidered Straight Kurta',
              'slug': 'indo-era-embroidered-straight-kurta',
              'main_image':
                  'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600',
              'brand_name': 'Indo Era',
              'ratings': 4.7,
              'rating_count': 320,
              'estimated_delivery_time': 'Tomorrow',
              'minimum_order_quantity': 1,
              'total_allowed_quantity': 10,
              'variants': [
                {
                  'id': 401,
                  'title': 'Purple / M',
                  'price': 2399.0,
                  'special_price': 821.0,
                  'currency_symbol': '₹',
                  'is_default': true,
                  'stock': 40,
                  'is_in_stock': true,
                }
              ],
            }),
          ),
          WatchStorySlide(
            id: 'slide_1_2',
            mediaUrl:
                'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
            mediaType: StoryMediaType.video,
            duration: const Duration(seconds: 7),
            caption: 'Behind the scenes at our Summer Collection shoot 🎥',
            createdAt: '2h ago',
            taggedProduct: ProductData.fromJson({
              'id': 302,
              'title': 'Pure Handloom Silk Scarf',
              'slug': 'pure-handloom-silk-scarf',
              'main_image':
                  'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=600',
              'brand_name': 'Carry Culture',
              'ratings': 4.9,
              'rating_count': 150,
              'estimated_delivery_time': '2 Days',
              'minimum_order_quantity': 1,
              'total_allowed_quantity': 5,
              'variants': [
                {
                  'id': 402,
                  'title': 'Emerald Green',
                  'price': 1299.0,
                  'special_price': 599.0,
                  'currency_symbol': '₹',
                  'is_default': true,
                  'stock': 25,
                  'is_in_stock': true,
                }
              ],
            }),
          ),
        ],
      ),

      // Store 2: Urban Footwear (Trendy Shoes & Flats)
      WatchStoryGroup(
        id: 'story_2',
        storeId: 'store_102',
        storeName: 'Urban Footwear',
        storeLogo:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        isSeen: false,
        isLive: false,
        slides: [
          WatchStorySlide(
            id: 'slide_2_1',
            mediaUrl:
                'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=1080',
            mediaType: StoryMediaType.image,
            caption: 'Trending block heels for daily office & casual wear 👠',
            createdAt: '3h ago',
            taggedProduct: ProductData.fromJson({
              'id': 303,
              'title': 'SHOMEE Trending Flat Sandals',
              'slug': 'shomee-trending-flat-sandals',
              'main_image':
                  'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=600',
              'brand_name': 'SHOMEE',
              'ratings': 4.5,
              'rating_count': 580,
              'estimated_delivery_time': '10-15 mins',
              'minimum_order_quantity': 1,
              'total_allowed_quantity': 6,
              'variants': [
                {
                  'id': 403,
                  'title': 'Size 6 / Beige',
                  'price': 999.0,
                  'special_price': 167.0,
                  'currency_symbol': '₹',
                  'is_default': true,
                  'stock': 18,
                  'is_in_stock': true,
                }
              ],
            }),
          ),
        ],
      ),

      // Store 3: Fresh Organic Farms
      WatchStoryGroup(
        id: 'story_3',
        storeId: 'store_103',
        storeName: 'Organic Farms',
        storeLogo:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        isSeen: false,
        isLive: false,
        slides: [
          WatchStorySlide(
            id: 'slide_3_1',
            mediaUrl:
                'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=1080',
            mediaType: StoryMediaType.image,
            caption: 'Freshly plucked organic Valencia oranges 🍊',
            createdAt: '5h ago',
            taggedProduct: ProductData.fromJson({
              'id': 304,
              'title': 'Fresh Organic Valencia Oranges (1kg)',
              'slug': 'fresh-organic-valencia-oranges',
              'main_image':
                  'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=600',
              'brand_name': 'Farm Fresh',
              'ratings': 4.8,
              'rating_count': 120,
              'estimated_delivery_time': '15 mins',
              'minimum_order_quantity': 1,
              'total_allowed_quantity': 10,
              'variants': [
                {
                  'id': 404,
                  'title': '1kg Pack',
                  'price': 180.0,
                  'special_price': 129.0,
                  'currency_symbol': '₹',
                  'is_default': true,
                  'stock': 50,
                  'is_in_stock': true,
                }
              ],
            }),
          ),
        ],
      ),

      // Store 4: Aroma & Scents (Perfumes)
      WatchStoryGroup(
        id: 'story_4',
        storeId: 'store_104',
        storeName: 'Aroma Scents',
        storeLogo:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
        isSeen: true,
        isLive: false,
        slides: [
          WatchStorySlide(
            id: 'slide_4_1',
            mediaUrl:
                'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=1080',
            mediaType: StoryMediaType.image,
            caption: 'Luxury French Bloom Eau de Parfum 🌸',
            createdAt: '8h ago',
            taggedProduct: ProductData.fromJson({
              'id': 305,
              'title': 'Luxury French Bloom Perfume 100ml',
              'slug': 'luxury-french-bloom-perfume',
              'main_image':
                  'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=600',
              'brand_name': 'Maison Luxe',
              'ratings': 4.9,
              'rating_count': 840,
              'estimated_delivery_time': 'Today',
              'minimum_order_quantity': 1,
              'total_allowed_quantity': 3,
              'variants': [
                {
                  'id': 405,
                  'title': '100ml Bottle',
                  'price': 3499.0,
                  'special_price': 1899.0,
                  'currency_symbol': '₹',
                  'is_default': true,
                  'stock': 12,
                  'is_in_stock': true,
                }
              ],
            }),
          ),
        ],
      ),

      // Store 5: Smart Tech Store
      WatchStoryGroup(
        id: 'story_5',
        storeId: 'store_105',
        storeName: 'Smart Tech',
        storeLogo:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
        isSeen: true,
        isLive: false,
        slides: [
          WatchStorySlide(
            id: 'slide_5_1',
            mediaUrl:
                'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=1080',
            mediaType: StoryMediaType.image,
            caption: 'Active Noise Cancelling Wireless Headphones 🎧',
            createdAt: '12h ago',
            taggedProduct: ProductData.fromJson({
              'id': 306,
              'title': 'SonicPro Wireless ANC Headphones',
              'slug': 'sonicpro-wireless-anc-headphones',
              'main_image':
                  'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600',
              'brand_name': 'SonicPro',
              'ratings': 4.6,
              'rating_count': 490,
              'estimated_delivery_time': 'Tomorrow',
              'minimum_order_quantity': 1,
              'total_allowed_quantity': 2,
              'variants': [
                {
                  'id': 406,
                  'title': 'Matte Black',
                  'price': 4999.0,
                  'special_price': 2499.0,
                  'currency_symbol': '₹',
                  'is_default': true,
                  'stock': 20,
                  'is_in_stock': true,
                }
              ],
            }),
          ),
        ],
      ),
    ];
  }
}
