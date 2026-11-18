import 'package:flutter_test/flutter_test.dart';
import 'package:msm_tubemate/config/app_constants.dart';

void main() {
  test('App constants verification', () {
    expect(AppConstants.appName, 'Msm TubeMate');
    expect(AppConstants.organization, 'ORG: msm.movin 2022');
    expect(AppConstants.copyright, 'ORG: msm.movin 2022');
  });
}
