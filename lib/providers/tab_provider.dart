import 'package:flutter/material.dart';

class TabProvider with ChangeNotifier {
  // Bắt đầu ở tab 0 (Shop)
  int _currentIndex = 0; 

  int get currentIndex => _currentIndex;

  /// Hàm này dùng để thay đổi tab
  void changeTab(int index) {
    _currentIndex = index;
    
    // Thông báo cho tất cả các widget đang "nghe" (như EntryPoint)
    // để chúng tự build lại
    notifyListeners(); 
  }
}