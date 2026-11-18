import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_constants.dart';

class SupabaseConfig {
  static bool isInitialized = false;

  static Future<void> initialize() async {
    try {
      if (AppConstants.supabaseUrl.isNotEmpty && AppConstants.supabaseAnonKey.isNotEmpty) {
        await Supabase.initialize(
          url: AppConstants.supabaseUrl,
          publishableKey: AppConstants.supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        isInitialized = true;
        debugPrint('[Supabase] Connected successfully to Msm TubeMate database');
      }
    } catch (e) {
      debugPrint('[Supabase] Offline Mode Active: $e');
      isInitialized = false;
    }
  }

  static SupabaseClient? get client {
    if (isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }
}
