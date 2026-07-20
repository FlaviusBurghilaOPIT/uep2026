import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setTab(int index, {bool notify = true}) {
    if (index < 0 || index > 3 || _currentIndex == index) return;
    _currentIndex = index;
    if (notify) notifyListeners();
  }
}
