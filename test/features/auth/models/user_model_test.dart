import 'package:flutter_test/flutter_test.dart';
import 'package:yalo/features/auth/models/user_model.dart';

void main() {
  group('UserRole', () {
    test('client role has correct name', () {
      expect(UserRole.client.name, 'client');
    });
    test('provider role has correct name', () {
      expect(UserRole.provider.name, 'provider');
    });
    test('admin role has correct name', () {
      expect(UserRole.admin.name, 'admin');
    });
    test('values contains all three roles', () {
      expect(UserRole.values.length, 3);
      expect(UserRole.values, contains(UserRole.client));
      expect(UserRole.values, contains(UserRole.provider));
      expect(UserRole.values, contains(UserRole.admin));
    });
  });
}
