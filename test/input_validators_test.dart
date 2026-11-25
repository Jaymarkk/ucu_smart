import 'package:flutter_test/flutter_test.dart';
import 'package:ucu_smart_plus/validation/input_validators.dart';

void main() {
  group('InputValidators', () {
    test('required text rejects empty and whitespace-only input', () {
      expect(
        InputValidators.requiredText(null, 'Username'),
        'Username is required.',
      );
      expect(
        InputValidators.requiredText('', 'Username'),
        'Username is required.',
      );
      expect(
        InputValidators.requiredText('   ', 'Username'),
        'Username is required.',
      );
      expect(InputValidators.requiredText('student42', 'Username'), isNull);
    });

    test('email validator rejects malformed and overlong addresses', () {
      expect(InputValidators.email(null), 'Email is required.');
      expect(
        InputValidators.email('not-an-email'),
        'Enter a valid email address.',
      );
      expect(
        InputValidators.email('${'a' * 245}@example.test'),
        'Enter a valid email address.',
      );
      expect(InputValidators.email('admin@example.test'), isNull);
    });

    test('login password validation checks presence without rewriting it', () {
      expect(InputValidators.loginPassword(null), 'Password is required.');
      expect(InputValidators.loginPassword(''), 'Password is required.');
      expect(InputValidators.loginPassword('  existing password  '), isNull);
    });
  });
}
