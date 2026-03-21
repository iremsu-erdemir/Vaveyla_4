import 'package:flutter_bloc/flutter_bloc.dart';

/// Panelden Siparişler sekmesine geçerken hangi alt sekmeyi (Bekleyen/Yolda/Teslim) göstereceğini tutar.
class CourierOrdersTabCubit extends Cubit<int> {
  CourierOrdersTabCubit() : super(0);

  void selectTab(int index) {
    emit(index.clamp(0, 2));
  }
}
