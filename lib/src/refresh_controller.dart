import 'package:flutter/foundation.dart';

class RefreshController extends ValueNotifier<int> {
  static const int HEAD_START_REFRESH = 4;
  static const int HEAD_END_REFRESH = 1;
  static const int FOOT_START_REFRESH = 2;
  static const int FOOT_END_REFRESH = 3;

  RefreshController() : super(0);

  void startHeadRefresh() {
    _ensureListeners();
    value = HEAD_START_REFRESH;
  }

  void _ensureListeners() {
    assert(
        hasListeners,
        "The RefresherController must attach to a widget first, "
        "the message is showing probably becourse the method is called before build . ");
  }

  void startFootRefresh() {
    _ensureListeners();
    value = HEAD_END_REFRESH;
  }

  void endHeadRefresh() {
    _ensureListeners();
    value = HEAD_START_REFRESH;
  }

  void endFootRefresh() {
    _ensureListeners();
    value = FOOT_END_REFRESH;
  }
}
