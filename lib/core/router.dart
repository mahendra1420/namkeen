import 'package:go_router/go_router.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/admin/add_product_screen.dart';
import '../features/admin/product_list_screen.dart';
import '../features/admin/category_list_screen.dart';
import '../features/admin/customer_list_screen.dart';
import '../features/admin/customer_ledger_screen.dart';
import '../features/admin/banner_management_screen.dart';
import '../features/admin/reports_screen.dart';
import '../features/admin/order_management_screen.dart';
import '../features/retailer/retailer_main_layout.dart';
import '../features/retailer/cart_screen.dart';
import '../features/retailer/product_details_screen.dart';
import '../features/retailer/order_details_screen.dart';
import '../shared/models/product_model.dart';
import '../shared/models/order_model.dart';
import '../shared/models/user_model.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/add-product',
      builder: (context, state) {
        final product = state.extra as ProductModel?;
        return AddProductScreen(productToEdit: product);
      },
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListScreen(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoryListScreen(),
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomerListScreen(),
    ),
    GoRoute(
      path: '/ledger',
      builder: (context, state) {
        final customer = state.extra as UserModel;
        return CustomerLedgerScreen(customer: customer);
      },
    ),
    GoRoute(
      path: '/banners',
      builder: (context, state) => const BannerManagementScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderManagementScreen(),
    ),
    GoRoute(
      path: '/retailer',
      builder: (context, state) => const RetailerMainLayout(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/product-details',
      builder: (context, state) {
        final product = state.extra as ProductModel;
        return ProductDetailsScreen(product: product);
      },
    ),
    GoRoute(
      path: '/order-details',
      builder: (context, state) {
        final order = state.extra as OrderModel;
        return OrderDetailsScreen(order: order);
      },
    ),
  ],
);
