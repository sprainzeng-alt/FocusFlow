import 'package:go_router/go_router.dart';

import '../features/focus/presentation/focus_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/search/presentation/search_page.dart';
import '../features/statistics/presentation/statistics_page.dart';
import '../features/tasks/presentation/tasks_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/tasks', builder: (context, state) => const TasksPage()),
    GoRoute(
      path: '/focus',
      builder: (context, state) {
        final taskId = state.uri.queryParameters['taskId'];
        final quick = state.uri.queryParameters['quick'] == 'true';
        return FocusPage(taskId: taskId, useQuickStart: quick);
      },
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsPage(),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
  ],
);
