import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  String? selectedColor;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.selectedColor,
  });

  double get totalPrice => product.price * quantity;
}
