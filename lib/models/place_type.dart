import 'package:flutter/material.dart';

enum PlaceType {
  hotel,
  restaurant,
  bar;

  static PlaceType fromTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'hotel':
        return PlaceType.hotel;
      case 'restaurant':
        return PlaceType.restaurant;
      case 'bar':
        return PlaceType.bar;
      default:
        return PlaceType.hotel;
    }
  }

  String get title {
    switch (this) {
      case PlaceType.hotel:
        return 'Hoteles';
      case PlaceType.restaurant:
        return 'Restaurantes';
      case PlaceType.bar:
        return 'Bares';
    }
  }

  String get singular {
    switch (this) {
      case PlaceType.hotel:
        return 'Hotel';
      case PlaceType.restaurant:
        return 'Restaurante';
      case PlaceType.bar:
        return 'Bar';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaceType.hotel:
        return Icons.hotel_rounded;
      case PlaceType.restaurant:
        return Icons.restaurant_rounded;
      case PlaceType.bar:
        return Icons.local_bar_rounded;
    }
  }

  String get emptyMessage {
    switch (this) {
      case PlaceType.hotel:
        return 'No hay hoteles disponibles';
      case PlaceType.restaurant:
        return 'No hay restaurantes disponibles';
      case PlaceType.bar:
        return 'No hay bares disponibles';
    }
  }

  String get placeholderImage {
    switch (this) {
      case PlaceType.hotel:
        return 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop';
      case PlaceType.restaurant:
        return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop';
      case PlaceType.bar:
        return 'https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=400&h=300&fit=crop';
    }
  }

  // '' significa que no se muestra en la UI
  String get hours {
    switch (this) {
      case PlaceType.hotel:
        return '';
      case PlaceType.restaurant:
        return '12:00 PM - 10:00 PM';
      case PlaceType.bar:
        return '5:00 PM - 2:00 AM';
    }
  }

  String get amenitiesLabel {
    switch (this) {
      case PlaceType.hotel:
        return 'Servicios incluidos:';
      case PlaceType.restaurant:
        return 'Especialidades:';
      case PlaceType.bar:
        return 'Especialidades:';
    }
  }

  // '' significa que el precio va inline en el header (hotel)
  String get priceLabel {
    switch (this) {
      case PlaceType.hotel:
        return '';
      case PlaceType.restaurant:
        return 'Rango de Precios: ';
      case PlaceType.bar:
        return 'Precios: ';
    }
  }

  String get scanLabel {
    switch (this) {
      case PlaceType.hotel:
        return 'Escanear QR del Hotel';
      case PlaceType.restaurant:
        return 'Escanear QR del Restaurante';
      case PlaceType.bar:
        return 'Escanear QR del Bar';
    }
  }
}
