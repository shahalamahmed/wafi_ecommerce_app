import 'package:flutter_test/flutter_test.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/owner/owner_management_provider.dart';

void main() {
  group('OwnerUserManagementState', () {
    test('filters by name email and phone', () {
      const users = [
        AppUser(
          uid: '1',
          email: 'owner@wafi.com',
          firstName: 'Owner',
          lastName: 'One',
          phone: '01700000001',
          profilePicture: '',
          role: UserRole.owner,
          isShopOwner: true,
          shopName: '',
        ),
        AppUser(
          uid: '2',
          email: 'customer@wafi.com',
          firstName: 'Customer',
          lastName: 'Two',
          phone: '01800000002',
          profilePicture: '',
          role: UserRole.customer,
          isShopOwner: false,
          shopName: '',
        ),
      ];

      const state = OwnerUserManagementState(
        users: users,
        searchQuery: '01800000002',
      );

      expect(state.filteredUsers.length, 1);
      expect(state.filteredUsers.first.uid, '2');
    });

    test('sorts owners first then latest updated users', () {
      final users = [
        AppUser(
          uid: 'customer-new',
          email: 'customer-new@wafi.com',
          firstName: 'Customer',
          lastName: 'New',
          phone: '',
          profilePicture: '',
          role: UserRole.customer,
          isShopOwner: false,
          shopName: '',
          updatedAt: DateTime(2026, 4, 29, 10),
        ),
        AppUser(
          uid: 'owner-old',
          email: 'owner-old@wafi.com',
          firstName: 'Owner',
          lastName: 'Old',
          phone: '',
          profilePicture: '',
          role: UserRole.owner,
          isShopOwner: true,
          shopName: '',
          updatedAt: DateTime(2026, 4, 28, 10),
        ),
        AppUser(
          uid: 'owner-new',
          email: 'owner-new@wafi.com',
          firstName: 'Owner',
          lastName: 'New',
          phone: '',
          profilePicture: '',
          role: UserRole.owner,
          isShopOwner: true,
          shopName: '',
          updatedAt: DateTime(2026, 4, 29, 12),
        ),
      ];

      final state = OwnerUserManagementState(users: users);

      expect(state.filteredUsers.map((user) => user.uid).toList(), [
        'owner-new',
        'owner-old',
        'customer-new',
      ]);
    });
  });
}
