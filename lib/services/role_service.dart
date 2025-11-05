import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/app_logger.dart';
import 'database_schema.dart';

class RoleService {
  RoleService({
    SupabaseClient? client,
    AppLogger? logger,
  })  : _client = client ?? Supabase.instance.client,
        _logger = logger ?? AppLogger.instance;

  final SupabaseClient _client;
  final AppLogger _logger;

  static String? _cachedUserId;
  static String? _cachedRole;

  Future<String> resolveCurrentUserRole({bool forceRefresh = false}) async {
    final userId = await _getCurrentUserId();

    if (userId == null) {
      _resetCache();
      _logger.w(
        '🔒 [RoleService] resolveCurrentUserRole called with no active user',
      );
      return 'user';
    }

    final cachedRole = _useCache(userId, forceRefresh: forceRefresh);
    if (cachedRole != null) {
      _logger.d('🔒 [RoleService] Cache hit for $userId -> $cachedRole');
      return cachedRole;
    }

    _logger.d(
      '🔒 [RoleService] Cache miss for $userId. forceRefresh=$forceRefresh, querying database',
    );

    Map<String, dynamic>? response;
    final attempts =
        forceRefresh ? _fallbackRetryDelays.take(1) : _fallbackRetryDelays;
    var attemptIndex = 0;

    for (final delay in attempts) {
      if (attemptIndex > 0) {
        _logger.d(
          '🔒 [RoleService] Retrying role fetch for $userId (attempt ${attemptIndex + 1}) after ${delay.inMilliseconds}ms',
        );
        await Future.delayed(delay);
      }

      try {
        response = await _fetchRoleRow(userId);
        if (response != null) {
          break;
        }
      } on PostgrestException catch (error, stackTrace) {
        _logger.w(
          '🔒 [RoleService] Failed to resolve role for $userId (PostgrestException)',
          error,
          stackTrace,
        );
        break;
      } catch (error, stackTrace) {
        _logger.w(
          '🔒 [RoleService] Failed to resolve role for $userId',
          error,
          stackTrace,
        );
        break;
      }

      attemptIndex++;
    }

    if (response != null) {
      final normalized = (response[DatabaseSchema.userRoles.role] as String?)
          ?.toLowerCase()
          .trim();

      final resolvedRole =
          (normalized == null || normalized.isEmpty) ? 'user' : normalized;

      _logger.d(
        '🔒 [RoleService] Normalized role for $userId -> $resolvedRole',
      );

      _cacheRole(userId, resolvedRole);
      return resolvedRole;
    }

    _logger.d('🔒 [RoleService] Falling back to default role for $userId');
    _cacheRole(userId, 'user');
    return 'user';
  }

  void clearCachedRole() {
    _resetCache();
  }

  Future<String?> _getCurrentUserId() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      _logger.d(
        '🔒 [RoleService] currentUser available immediately: ${user.id}',
      );
      return user.id;
    }

    _logger.d(
      '🔒 [RoleService] currentUser missing, waiting for auth session...',
    );
    for (final delay in _waitIntervals) {
      await Future.delayed(delay);
      final refreshedUser = _client.auth.currentUser;
      if (refreshedUser != null) {
        _logger.d(
          '🔒 [RoleService] currentUser resolved after ${delay.inMilliseconds}ms: ${refreshedUser.id}',
        );
        return refreshedUser.id;
      }
    }

    _logger.w('🔒 [RoleService] Unable to resolve currentUser after retries');
    return null;
  }

  static const List<Duration> _waitIntervals = <Duration>[
    Duration(milliseconds: 50),
    Duration(milliseconds: 100),
    Duration(milliseconds: 150),
  ];

  static const List<Duration> _fallbackRetryDelays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 75),
    Duration(milliseconds: 150),
  ];

  Future<Map<String, dynamic>?> _fetchRoleRow(String userId) {
    return _client
        .from(DatabaseSchema.userRoles.table)
        .select(DatabaseSchema.userRoles.role)
        .eq(DatabaseSchema.userRoles.userId, userId)
        .limit(1)
        .maybeSingle();
  }

  static String? _useCache(
    String userId, {
    bool forceRefresh = false,
  }) {
    if (forceRefresh) {
      return null;
    }

    if (_cachedUserId == userId && _cachedRole != null) {
      return _cachedRole;
    }

    return null;
  }

  static void _cacheRole(String userId, String role) {
    _cachedUserId = userId;
    _cachedRole = role;
  }

  static void _resetCache() {
    _cachedUserId = null;
    _cachedRole = null;
  }
}
