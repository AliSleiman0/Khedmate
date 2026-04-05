# Flutter Patterns — Khudmati Mobile Apps

Both apps (`mobile-customer/` and `mobile-provider/`) share the same architecture. Code lives under `lib/`.

---

## Project structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart         ← MaterialApp + theme
│   ├── router.dart      ← GoRouter setup
│   └── theme.dart
├── core/
│   ├── api/
│   │   └── api_client.dart      ← Dio instance (singleton)
│   ├── constants/
│   │   └── colors.dart          ← AppColors
│   └── ...
├── features/
│   └── {feature-name}/
│       ├── data/
│       │   └── {feature}_repository.dart
│       ├── domain/
│       │   └── {model}.dart
│       └── presentation/
│           ├── {feature}_screen.dart    ← UI only
│           └── {feature}_provider.dart  ← Riverpod state
└── shared/
    └── widgets/
```

---

## AppColors

File: `core/constants/colors.dart`

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color brandBlue    = Color(0xFF1B4F72);
  static const Color amber        = Color(0xFFF39C12);
  static const Color success      = Color(0xFF27AE60);
  static const Color danger       = Color(0xFFE74C3C);
  static const Color surface      = Color(0xFFF5F7FA);
  static const Color textPrimary  = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
}
```

**Never hardcode hex values in widgets.** Always use `AppColors.*`.

---

## Riverpod — AsyncNotifierProvider (standard state pattern)

Every screen that loads data uses `AsyncNotifierProvider`. The notifier lives in `*_provider.dart`.

```dart
// features/jobs/presentation/job_feed_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/job_repository.dart';

class JobFeedNotifier extends AsyncNotifier<List<JobSummary>> {
  @override
  Future<List<JobSummary>> build() async {
    return _load();
  }

  Future<List<JobSummary>> _load() {
    final repo = ref.read(jobRepositoryProvider);
    return repo.getAvailableJobs();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final jobFeedNotifierProvider =
    AsyncNotifierProvider<JobFeedNotifier, List<JobSummary>>(JobFeedNotifier.new);
```

---

## Riverpod — consuming in a screen

```dart
// features/jobs/presentation/job_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import 'job_feed_provider.dart';

class JobFeedScreen extends ConsumerWidget {
  const JobFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJobs = ref.watch(jobFeedNotifierProvider);

    return Directionality(
      textDirection: TextDirection.rtl,       // ← RTL wrapper on every screen
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: const Text(
            'الطلبات',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: asyncJobs.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandBlue)),
          error: (e, _) => _ErrorState(
            onRefresh: () => ref.read(jobFeedNotifierProvider.notifier).refresh()),
          data: (jobs) => jobs.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: jobs.length,
                  itemBuilder: (ctx, i) => _JobCard(job: jobs[i]),
                ),
        ),
      ),
    );
  }
}
```

**Rules:**
- Wrap every screen root with `Directionality(textDirection: TextDirection.rtl, ...)`.
- Use `fontFamily: 'Cairo'` for Arabic text, `fontFamily: 'Inter'` for numbers/English.
- Always handle all three `asyncJobs.when` cases: `loading`, `error`, `data`.

---

## Empty and error state widgets

Reuse this pattern for consistency:

```dart
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 72, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'لا توجد عناصر',                   // ← Arabic empty message
            style: TextStyle(fontFamily: 'Cairo', fontSize: 17, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _ErrorState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('تعذر التحميل', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Repository (data layer)

```dart
// features/jobs/data/job_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class JobRepository {
  final ApiClient _client;

  JobRepository(this._client);

  Future<List<JobSummary>> getAvailableJobs({int page = 1, int pageSize = 20}) async {
    final response = await _client.dio.get(
      '/providers/jobs/available',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final items = (response.data['data']['items'] as List);
    return items.map((e) => JobSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<JobDetail> getJobById(String jobId) async {
    final response = await _client.dio.get('/providers/jobs/$jobId');
    return JobDetail.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> respondToJob(String jobId, String action) async {
    await _client.dio.post(
      '/providers/jobs/$jobId/respond',
      data: {'action': action},
    );
  }
}

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(ApiClient());
});
```

**Rules:**
- All API calls go through `_client.dio` — never use `http` package directly.
- Map `response.data['data']` — the backend wraps responses in `{ success, data }`.
- Repositories expose clean domain types (not raw maps).

---

## Domain model

```dart
// features/jobs/domain/job_summary.dart
class JobSummary {
  final String id;
  final String referenceNumber;
  final String categoryId;
  final String categoryName;
  final double distanceKm;
  final String district;
  final int secondsRemaining;
  final DateTime postedAt;
  final bool hasPhotos;

  const JobSummary({
    required this.id,
    required this.referenceNumber,
    required this.categoryId,
    required this.categoryName,
    required this.distanceKm,
    required this.district,
    required this.secondsRemaining,
    required this.postedAt,
    required this.hasPhotos,
  });

  factory JobSummary.fromJson(Map<String, dynamic> json) => JobSummary(
        id: (json['jobId'] ?? json['id'] ?? '').toString(),
        referenceNumber: json['referenceNumber'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        district: json['district'] as String? ?? '',
        secondsRemaining: (json['secondsRemaining'] as num?)?.toInt() ?? 0,
        postedAt: json['postedAt'] != null
            ? DateTime.parse(json['postedAt'] as String)
            : DateTime.now(),
        hasPhotos: json['hasPhotos'] as bool? ?? false,
      );
}
```

**Pattern:** `fromJson` uses null-safe fallbacks (`as String? ?? ''`). Use `copyWith` for immutable updates.

---

## GoRouter setup

File: `app/router.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/jobs/presentation/job_feed_screen.dart';
import '../features/jobs/presentation/job_detail_screen.dart';

const _authRoutes = {'/welcome', '/login', '/register'};

bool _isAuthRoute(String location) =>
    _authRoutes.contains(location) || location.startsWith('/otp');

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);
      if (authAsync.isLoading) return null;
      final isAuthenticated = authAsync.valueOrNull is AuthAuthenticated;
      final onAuthRoute = _isAuthRoute(state.uri.toString());
      if (isAuthenticated && onAuthRoute) return '/jobs';
      if (!isAuthenticated && !onAuthRoute) return '/welcome';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/jobs', builder: (_, __) => const JobFeedScreen()),
      GoRoute(
        path: '/job-detail/:jobId',
        builder: (_, state) => JobDetailScreen(jobId: state.pathParameters['jobId']!),
      ),
    ],
  );
});
```

**Adding a new route:** append a `GoRoute` to the `routes` list. Use `context.go('/path')` to navigate, `context.push('/path')` to push on the stack.

---

## ApiClient (Dio)

File: `core/api/api_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',  // Android emulator → localhost
  );

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Attempt token refresh ...
        }
        handler.next(error);
      },
    ));
  }
}
```

---

## main.dart / ProviderScope setup

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'core/api/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          AuthRepository(ApiClient()),
        ),
      ],
      child: const App(),
    ),
  );
}
```

---

## pubspec.yaml key dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.x
  go_router: ^13.x
  dio: ^5.x
  flutter_secure_storage: ^9.x
  signalr_netcore: ^1.x        # SignalR client
  google_maps_flutter: ^2.x    # Live tracking screens
  geolocator: ^11.x            # GPS
  cached_network_image: ^3.x
  intl: ^0.19.x

dev_dependencies:
  flutter_lints: ^3.x
  build_runner: ^2.x
```

---

## RTL checklist (mandatory for every new screen)

- [ ] Root widget wrapped in `Directionality(textDirection: TextDirection.rtl, ...)`
- [ ] All visible text uses `fontFamily: 'Cairo'` (Arabic) or `fontFamily: 'Inter'` (numbers/English)
- [ ] No hardcoded `Alignment.centerLeft` / `EdgeInsets.only(left: ...)` — use `start`/`end` variants
- [ ] Icons that imply direction (arrows, chevrons) flip correctly in RTL
- [ ] Test on an Arabic locale device/emulator before marking done
