import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/features/auth/presentation/login_screen.dart';
import 'package:schemora_frontend/features/health/presentation/health_screen.dart';
import 'package:schemora_frontend/features/profile/presentation/profile_form_screen.dart';
import 'package:schemora_frontend/features/profile/presentation/profile_type_screen.dart';
import 'package:schemora_frontend/features/schemes/presentation/dashboard_screen.dart';
import 'package:schemora_frontend/features/schemes/presentation/scheme_catalog_screen.dart';
import 'package:schemora_frontend/features/schemes/presentation/scheme_detail_screen.dart';
import 'package:schemora_frontend/features/recommendations/presentation/recommendation_screen.dart';
import 'package:schemora_frontend/features/ai_assistant/presentation/assistant_chat_screen.dart';
import 'package:schemora_frontend/features/documents/presentation/document_upload_screen.dart';
import 'package:schemora_frontend/features/documents/presentation/scheme_checklist_screen.dart';
import 'package:schemora_frontend/features/saved_schemes/presentation/saved_schemes_screen.dart';
import 'package:schemora_frontend/features/admin/presentation/admin_login_screen.dart';
import 'package:schemora_frontend/features/admin/presentation/admin_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // /health-diagnostic is kept for developer use only — not shown to users on startup.
      GoRoute(
        path: '/health-diagnostic',
        builder: (context, state) => const HealthScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      // Profile type selection — new onboarding first step
      GoRoute(
        path: '/profile-type',
        builder: (context, state) => const ProfileTypeScreen(),
      ),
      // /profile-form is the dynamic profile form reached from profile-type selection
      GoRoute(
        path: '/profile-form',
        builder: (context, state) => const ProfileFormScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileFormScreen(),
      ),
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const SchemeCatalogScreen(),
      ),
      GoRoute(
        path: '/catalog/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SchemeDetailScreen(schemeId: id);
        },
      ),
      GoRoute(
        path: '/recommendations',
        builder: (context, state) => const RecommendationScreen(),
      ),
      GoRoute(
        path: '/assistant',
        builder: (context, state) => const AssistantChatScreen(),
      ),
      GoRoute(
        path: '/documents/upload',
        builder: (context, state) => const DocumentUploadScreen(),
      ),
      GoRoute(
        path: '/checklist/:schemeId',
        builder: (context, state) {
          final schemeId = state.pathParameters['schemeId']!;
          return SchemeChecklistScreen(schemeId: schemeId);
        },
      ),
      GoRoute(
        path: '/saved-schemes',
        builder: (context, state) => const SavedSchemesScreen(),
      ),
      // Admin routes (P0-703)
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
