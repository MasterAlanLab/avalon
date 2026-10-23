import 'package:avalon/cloud/cloud_development_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release and ordinary builds keep unfinished Cloud hidden', () {
    expect(
      CloudDevelopmentConfig.fromBuild(
        release: true,
        enabled: true,
        baseUrl: 'https://cloud.example.invalid',
      ),
      isNull,
    );
    expect(
      CloudDevelopmentConfig.fromBuild(
        release: false,
        enabled: false,
        baseUrl: 'https://cloud.example.invalid',
      ),
      isNull,
    );
    expect(
      CloudDevelopmentConfig.fromBuild(
        release: false,
        enabled: true,
        baseUrl: '',
      ),
      isNull,
    );
  });

  test('invalid preview origins never turn into local startup failures', () {
    for (final url in [
      'http://cloud.example.invalid',
      'https://secret@cloud.example.invalid',
      'https://cloud.example.invalid/v1',
      'https://cloud.example.invalid?token=secret',
      'https://cloud.example.invalid#secret',
      'relative',
    ]) {
      expect(
        CloudDevelopmentConfig.fromBuild(
          release: false,
          enabled: true,
          baseUrl: url,
        ),
        isNull,
      );
    }
  });
}
