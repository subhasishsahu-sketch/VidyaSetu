import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../modules/home/screens/home_screen.dart';
import '../modules/roadmap/screens/roadmap_screen.dart';
import '../modules/assessment/screens/test_screen.dart';
import '../modules/concept_repair/screens/repair_screen.dart';
import '../modules/replan/screens/replan_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/home',
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/roadmap',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RoadmapScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/test',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const TestScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/repair',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RepairScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/replan',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ReplanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
  ],
);
