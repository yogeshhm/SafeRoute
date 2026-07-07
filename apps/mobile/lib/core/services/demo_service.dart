class DemoService {
  static bool _isDemo = false;
  static bool get isDemo => _isDemo;

  static void enter() => _isDemo = true;
  static void exit() => _isDemo = false;
}
