/// Route paths, in one place so screens don't hand-build strings.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const setup = '/setup';
  static const unlock = '/unlock';
  static const home = '/';
  static const add = '/add';
  static const settings = '/settings';
  static const changePin = '/settings/change-pin';

  static String detail(String id) => '/pin/$id';
  static String edit(String id) => '/pin/$id/edit';
}
