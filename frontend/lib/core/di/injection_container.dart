import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

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
import '../../features/chat/presentation/cubit/chat_cubit.dart';

// Service Locator instance
final sl = GetIt.instance;

Future<void> init() async {
  // --- Core ---
  // Register UserService for global user state
  sl.registerLazySingleton<UserService>(() => UserService());

  // Register Dio (HTTP client)
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        // Replace with your actual backend URL
        // For local development with Android emulator, use 10.0.2.2
        // For local development with iOS simulator or physical device on same network, use your machine's local IP
        baseUrl: 'http://localhost:3000/api', // Use localhost for iOS Simulator
        connectTimeout: const Duration(milliseconds: 5000), // 5 seconds
        receiveTimeout: const Duration(milliseconds: 3000), // 3 seconds
      ),
    );
    // Add interceptors if needed (e.g., for logging, auth tokens)
    // dio.interceptors.add(LogInterceptor(responseBody: true));
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

  // --- External ---
  // (Already registered Dio above)

  // --- WebSocket ---
  // WebSocket setup might be handled differently, perhaps within specific feature repositories
  // or a dedicated core service, depending on how it's used.
}
