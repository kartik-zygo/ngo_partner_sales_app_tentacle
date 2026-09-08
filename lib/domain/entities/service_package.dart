import 'package:equatable/equatable.dart';

class ServicePackage extends Equatable {
  const ServicePackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.category,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String? category;
  final bool isActive;

  ServicePackage copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isActive,
  }) {
    return ServicePackage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, description, price, category, isActive];
}
