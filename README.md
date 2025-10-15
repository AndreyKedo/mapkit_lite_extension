# mapkit_lite_extension

[![Pub](https://img.shields.io/pub/v/mapkit_lite_extension.svg)](https://pub.dev/packages/mapkit_lite_extension)

Расширение для [yandex_mapkit_lite](https://pub.dev/packages/yandex_mapkit_lite), которое предоставляет удобный API для работы с Яндекс Картами во Flutter приложениях.

## Основные возможности

- Удобный контроллер для управления состоянием карты
- Система коллекций для управления объектами на карте
- Поддержка кластеризации маркеров
- Провайдеры для создания маркеров из различных источников (SVG, виджеты)
- Реактивное обновление интерфейса при изменении данных

## Быстрый старт

### Базовое использование

```dart
import 'package:flutter/material.dart';
import 'package:mapkit_lite_extension/mapkit_lite_extension.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AspectRatio(
          aspectRatio: 16 / 9,
          child: ExtendedMapWidget(),
        ),
      ),
    );
  }
}
```

### Использование с контроллером

```dart
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final ExtendedMapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExtendedMapController();
    
    // Добавляем маркер на карту
    _addMarker();
  }

  void _addMarker() {
    final marker = PlacemarkObject(
      latLng: (latitude: 55.7558, longitude: 37.6173), // Москва
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage('assets/marker.png'),
          anchor: const Offset(0.5, 1),
        ),
      ),
    );
    
    _controller.mapObjects.addPlacemark(marker);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ExtendedMapWidget(
        controller: _controller,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Основные компоненты

### ExtendedMapController

Контроллер для управления состоянием карты и коллекциями объектов.

Основные возможности:
- Управление жестами (наклон, масштабирование, вращение, прокрутка)
- Управление режимами (ночной режим, 2D режим)
- Работа с коллекциями объектов на карте

```dart
final controller = ExtendedMapController();

// Отключение всех жестов
controller.tiltGesturesEnabled = false;
controller.zoomGesturesEnabled = false;
controller.rotateGesturesEnabled = false;
controller.scrollGesturesEnabled = false;

// Включение ночного режима
controller.nightModeEnabled = true;
```

### ExtendedMapObjectCollection

Коллекция для управления объектами на карте. Позволяет добавлять маркеры и кластеры.

```dart
final collection = ExtendedMapObjectCollection('my_collection');

// Добавление простого маркера
final marker = PlacemarkObject(
  latLng: (latitude: 55.7558, longitude: 37.6173),
  icon: PlacemarkIcon.single(
    PlacemarkIconStyle(
      image: BitmapDescriptor.fromAssetImage('assets/marker.png'),
    ),
  ),
);

collection.addPlacemark(marker);

// Создание кластера
final cluster = collection.addPlacemarkCollection(
  ClusterListener(), // Реализация ClusterListener
  options: ClusterOptions(
    minZoom: 0,
    maxZoom: 20,
    radius: 150,
  ),
);
```

### PlacemarkProvider

Провайдеры для создания маркеров из различных источников.

#### SvgPlacemarkProvider

Создание маркеров из SVG файлов:

```dart
final provider = SvgPlacemarkProvider(
  assetKey: 'assets/icons/marker.svg',
  viewConfiguration: const Size(48, 48),
);

final icon = await provider.resolve();
```