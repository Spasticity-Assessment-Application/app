import 'package:go_router/go_router.dart';
import 'package:poc/features/home/presentation/home_page.dart';
import 'package:poc/features/camera/camera.dart';
import 'package:poc/features/photo_display/photo_display.dart';
import 'package:poc/features/photo_display/presentation/pages/result_page.dart';
import 'package:poc/features/analysis/presentation/analysis_page.dart';
import 'package:poc/features/camera_video/presentation/video_confirm_page.dart';
import 'package:poc/features/patient/presentation/patients_page.dart';
import 'package:poc/features/patient/presentation/add_patient_page.dart';
import 'package:poc/features/patient/presentation/patient_detail_page.dart';

class AppRouter {
  GoRouter get router => GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(path: '/camera', builder: (context, state) => const CameraPage()),
      GoRoute(
        path: '/photo-display',
        builder: (context, state) => const PhotoDisplayPage(),
      ),
      GoRoute(path: '/result', builder: (context, state) => const ResultPage()),
      GoRoute(
        path: '/analyse',
        builder: (context, state) => const AnalysisPage(),
      ),
      GoRoute(
        path: '/video-confirm',
        builder: (context, state) {
          final videoPath = state.extra as String? ?? '';
          return VideoConfirmPage(videoPath: videoPath);
        },
      ),
      GoRoute(
        path: '/patients',
        builder: (context, state) => const PatientsPage(),
      ),

      GoRoute(
        path: '/patients/add',
        builder: (context, state) => const AddPatientPage(),
      ),
      GoRoute(
        path: '/patients/detail',
        builder: (context, state) {
          final idx = state.extra as int?; // on passe l'index
          return PatientDetailPage(index: idx ?? 0);
        },
      ),
    ],
  );
}
