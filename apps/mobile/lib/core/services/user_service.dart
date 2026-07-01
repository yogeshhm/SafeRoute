import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static final _db = Supabase.instance.client;

  // Demo IDs for testing without auth
  static const _demoDriverId = '00000000-0000-4000-8000-000000000102';
  static const _demoParentId = '00000000-0000-4000-8000-000000000201';

  static Future<Map<String, dynamic>> getDriverProfile() async {
    final authUser = _db.auth.currentUser;
    if (authUser != null) {
      return await _db
          .from('users')
          .select('id, full_name, role')
          .eq('auth_user_id', authUser.id)
          .single();
    }
    return await _db
        .from('users')
        .select('id, full_name, role')
        .eq('id', _demoDriverId)
        .single();
  }

  static Future<Map<String, dynamic>> getParentProfile() async {
    final authUser = _db.auth.currentUser;
    if (authUser != null) {
      return await _db
          .from('users')
          .select('id, full_name, role')
          .eq('auth_user_id', authUser.id)
          .single();
    }
    return await _db
        .from('users')
        .select('id, full_name, role')
        .eq('id', _demoParentId)
        .single();
  }

  static Future<void> signOut() async {
    await _db.auth.signOut();
  }
}
