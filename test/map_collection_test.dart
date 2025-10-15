import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_lite_extension/mapkit_lite_extension.dart';
import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart';

void main() {
  group('MapCollectionTree', () {
    test('дочерние вложенные коллекции получают ссылку на notifier при прикреплении к дереву', () {
      // Создаем дерево коллекций
      final tree = MapCollectionTree();

      // Создаем первую коллекцию
      final firstCollection = ExtendedMapObjectCollection('first_collection');

      // Создаем вторую коллекцию
      final secondCollection = ExtendedMapObjectCollection('second_collection');

      // Добавляем вторую коллекцию в первую
      firstCollection.addCollection(secondCollection);

      // Проверяем, что вторая коллекция пока не имеет notifier
      expect(secondCollection.notifier, isNull);

      // Добавляем первую коллекцию в корень дерева
      tree.root.addCollection(firstCollection);

      // Проверяем, что первая коллекция получила notifier
      expect(firstCollection.notifier, tree);

      // Проверяем, что вторая коллекция также получила notifier
      expect(secondCollection.notifier, tree);
    });

    test('вложенная структура коллекций правильно распространяет notifier', () {
      // Создаем дерево коллекций
      final tree = MapCollectionTree();

      // Создаем коллекции
      final level1Collection = ExtendedMapObjectCollection('level1');
      final level2Collection = ExtendedMapObjectCollection('level2');
      final level3Collection = ExtendedMapObjectCollection('level3');

      // Создаем структуру: level1 -> level2 -> level3
      level2Collection.addCollection(level3Collection);
      level1Collection.addCollection(level2Collection);

      // Проверяем, что level2 и level3 пока не имеют notifier
      expect(level2Collection.notifier, isNull);
      expect(level3Collection.notifier, isNull);

      // Добавляем level1 в корень дерева
      tree.root.addCollection(level1Collection);

      // Проверяем, что все коллекции получили notifier
      expect(level1Collection.notifier, tree);
      expect(level2Collection.notifier, tree);
      expect(level3Collection.notifier, tree);
    });

    test('дочерние элементы, добавленные после прикрепления к дереву, получают notifier', () {
      // Создаем дерево коллекций
      final tree = MapCollectionTree();

      // Создаем коллекцию
      final parentCollection = ExtendedMapObjectCollection('parent');

      // Добавляем коллекцию в корень дерева
      tree.root.addCollection(parentCollection);

      // Проверяем, что коллекция получила notifier
      expect(parentCollection.notifier, tree);

      // Создаем новую коллекцию и добавляем ее в родительскую коллекцию
      final childCollection = ExtendedMapObjectCollection('child');
      parentCollection.addCollection(childCollection);

      // Проверяем, что новая коллекция также получила notifier
      expect(childCollection.notifier, tree);
    });

    test('кластеры, добавленные после прикрепления к дереву, получают notifier', () {
      // Создаем дерево коллекций
      final tree = MapCollectionTree();

      // Создаем коллекцию
      final collection = ExtendedMapObjectCollection('collection');

      // Добавляем коллекцию в корень дерева
      tree.root.addCollection(collection);

      // Проверяем, что коллекция получила notifier
      expect(collection.notifier, tree);

      // Создаем кластер и добавляем его в коллекцию
      final cluster = collection.addPlacemarkCollection(_TestClusterListener());

      // Проверяем, что кластер также получила notifier
      expect(cluster.notifier, tree);
    });

    test('дочерние вложенные кластеры получают ссылку на notifier при прикреплении к дереву', () {
      // Создаем дерево коллекций
      final tree = MapCollectionTree();

      // Создаем коллекцию
      final collection = ExtendedMapObjectCollection('collection');

      // Создаем кластер
      final cluster = collection.addPlacemarkCollection(_TestClusterListener());

      // Проверяем, что кластер пока не имеет notifier
      expect(cluster.notifier, isNull);

      // Добавляем коллекцию в корень дерева
      tree.root.addCollection(collection);

      // Проверяем, что коллекция получила notifier
      expect(collection.notifier, tree);

      // Проверяем, что кластер также получила notifier
      expect(cluster.notifier, tree);
    });
  });
}

class _TestClusterListener implements ClusterListener {
  @override
  Future<PlacemarkMapObject> onAddCluster(ClusterableMapObject cluster) async {
    throw UnimplementedError();
  }
}
