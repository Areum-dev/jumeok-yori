import '../models/menu_item.dart';
import '../models/starter_menu.dart';

/// 추천/사장님 메뉴 데이터 접근 인터페이스
abstract class MenuRepository {
  Future<List<MenuItem>> fetchApprovedMenus();
  Future<List<StarterMenu>> fetchStarterMenus();
  Future<List<MenuItem>> fetchOwnerMenus(String ownerId);
  Future<void> submitMenu(MenuItem menu);
  Future<void> approveMenu(String menuId);
  Future<void> rejectMenu(String menuId, String note);
}
