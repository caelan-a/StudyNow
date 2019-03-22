import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studynowlib/studynowlib.dart';

void main() {
  const MethodChannel channel = MethodChannel('studynowlib');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Studynowlib.platformVersion, '42');
  });
}
