import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/repository/supabase_key_codec.dart';

void main() {
  group('Supabase key codec (camelCase ↔ snake_case)', () {
    test('camelToSnake handles acronym suffixes like the Swift bridge', () {
      expect(camelToSnakeKey('fullName'), 'full_name');
      expect(camelToSnakeKey('memberNumber'), 'member_number');
      expect(camelToSnakeKey('branchID'), 'branch_id');
      expect(camelToSnakeKey('avatarURL'), 'avatar_url');
      expect(camelToSnakeKey('parentUserIDs'), 'parent_user_ids');
      expect(camelToSnakeKey('worldTaekwondoID'), 'world_taekwondo_id');
      expect(camelToSnakeKey('id'), 'id');
    });

    test('snakeToCamel restores acronym suffixes', () {
      expect(snakeToCamelKey('full_name'), 'fullName');
      expect(snakeToCamelKey('branch_id'), 'branchID');
      expect(snakeToCamelKey('avatar_url'), 'avatarURL');
      expect(snakeToCamelKey('parent_user_ids'), 'parentUserIDs');
      expect(snakeToCamelKey('world_taekwondo_id'), 'worldTaekwondoID');
    });

    test('round-trips the keys for every camelCase property name', () {
      for (final key in [
        'fullName',
        'fullNameAr',
        'branchID',
        'primaryCoachID',
        'avatarURL',
        'parentUserIDs',
        'worldTaekwondoID',
        'imageRightsConsentDate',
        'currentBelt',
        'gradingReadiness',
      ]) {
        expect(snakeToCamelKey(camelToSnakeKey(key)), key,
            reason: 'round-trip failed for $key');
      }
    });

    test('encodeKeys/decodeRow recurse into nested maps and lists', () {
      final camel = {
        'branchID': 'b1',
        'currentBelt': {'color': 'blue', 'awardedAt': '2024-01-01'},
        'beltHistory': [
          {'color': 'green', 'awardedAt': '2023-01-01'},
        ],
        'parentUserIDs': ['u1', 'u2'],
      };
      final snake = encodeKeys(camel) as Map<String, dynamic>;
      expect(snake['branch_id'], 'b1');
      expect((snake['current_belt'] as Map)['awarded_at'], '2024-01-01');
      expect((snake['belt_history'] as List).first['awarded_at'], '2023-01-01');
      expect(snake['parent_user_ids'], ['u1', 'u2']); // value list untouched

      final back = decodeRow(snake);
      expect(back['branchID'], 'b1');
      expect((back['currentBelt'] as Map)['awardedAt'], '2024-01-01');
      expect((back['beltHistory'] as List).first['awardedAt'], '2023-01-01');
    });
  });
}
