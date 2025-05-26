import 'package:dio/dio.dart';
import 'package:frontend/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:frontend/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

// Core Services
import '../services/user_service.dart';

// Features - Auth
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
// Features - Rooms (Home Page)
import '../../features/home/data/datasources/room_remote_data_source.dart';
import '../../features/home/data/repositories/room_repository.dart';
import '../../features/home/presentation/cubit/room_cubit.dart';
// Features - Chat
import '../../features/chat/data/datasources/chat_remote_data_source.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart'; // Import ProfileCubit and Repository

// Features - Subjects
import '../../features/subjects/data/datasources/subjects_remote_data_source.dart';
import '../../features/subjects/domain/repositories/subjects_repository.dart';
import '../../features/subjects/presentation/cubit/subjects_cubit.dart';

// Service Locator instance
final sl = GetIt.instance;

Future<void> init() async {
  // --- Core ---
  // Register UserService for global user state
  sl.registerLazySingleton<UserService>(() => UserService());

  // Register http.Client for SubjectsRemoteDataSource
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // Register Dio (HTTP client)
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        // Platform-specific base URL
        baseUrl: Platform.isAndroid
            ? 'http://10.0.2.2:3000/api' // Android emulator
            : 'http://localhost:3000/api', // iOS simulator
        connectTimeout: const Duration(seconds: 10), // Increased timeout
        receiveTimeout: const Duration(seconds: 10), // Increased timeout
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    // Add logging interceptor for debugging
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }

    // Auth token interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('Making request to: ${options.uri}');
          }
          final userService = sl<UserService>();
          final user = userService.getCurrentUser();
          if (user != null && user.token != null) {
            options.headers['Authorization'] = 'Bearer ${user.token}';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            print('DioError: ${error.message}');
            print('Error type: ${error.type}');
            print('Error response: ${error.response}');
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  });

  // --- Features ---

  // Authentication
  // Bloc/Cubit - Use registerFactory for Blocs/Cubits as they often have state
  sl.registerFactory(() => AuthCubit(authRepository: sl(), userService: sl()));

  // Repository - Use registerLazySingleton for repositories
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl()));

  // Data Sources - Use registerLazySingleton for data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(dioClient: sl()));

  // Rooms (Home)
  sl.registerFactory(() => RoomCubit(roomRepository: sl(), userService: sl()));
  sl.registerLazySingleton<RoomRepository>(
      () => RoomRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<RoomRemoteDataSource>(
      () => RoomRemoteDataSourceImpl(dioClient: sl()));

  // Chat
  // Note: ChatCubit needs the roomId, so it cannot be registered directly here.
  // It should be created in the ChatPage widget using BlocProvider.value or BlocProvider
  // and passing the roomId. We register the Repository and DataSource.
  // sl.registerFactoryParam<ChatCubit, int, void>( // Example if using factory with param
  //   (roomId, _) => ChatCubit(chatRepository: sl(), currentRoomId: roomId),
  // );
  sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(dioClient: sl()));

  // Profile
  // Register the placeholder repository first
  sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(remoteDataSource: sl()));
  // Register the Cubit, depending on the repository
  sl.registerFactory(() => ProfileCubit(sl()));

  // Subjects Feature
  sl.registerLazySingleton<SubjectsRemoteDataSource>(
    () => SubjectsRemoteDataSourceImpl(
      client: sl(),
      userService: sl(),
      baseUrl: sl(),
    ),
  );

  sl.registerLazySingleton<SubjectsRepository>(
    () => SubjectsRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerFactory(
    () => SubjectsCubit(
      repository: sl(),
    ),
  );

  // Register baseUrl for SubjectsRemoteDataSource
  sl.registerLazySingleton<String>(() => Platform.isAndroid
          ? 'http://10.0.2.2:3000' // Android emulator
          : 'http://localhost:3000' // iOS simulator
      );

  // --- External ---
  // (Already registered Dio above)

  // --- WebSocket ---
  // WebSocket setup might be handled differently, perhaps within specific feature repositories
  // or a dedicated core service, depending on how it's used.
  sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(dio: sl()));
}
