@TestOn('vm')
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_vector_tiles/src/render/label_painter.dart';
import 'package:flutter_map_vector_tiles/src/render/symbol_layouter.dart';
import 'package:flutter_map_vector_tiles/src/style/theme.dart';
import 'package:flutter_map_vector_tiles/src/style/theme_reader.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> renderLabel(String fontFamily) async {
  final theme = const ThemeReader().read({
    'layers': [
      {
        'id': 'place',
        'type': 'symbol',
        'source': 's',
        'source-layer': 'places',
        'layout': {
          'text-field': '{name}',
          'text-size': 24,
          'text-font': [fontFamily],
        },
        'paint': {'text-color': '#111111'},
      },
    ],
  });
  final layer = theme.layers.single as SymbolThemeLayer;
  final symbol = PlacedSymbol(
    instance: SymbolInstance(
      layer: layer,
      layerIndex: 0,
      anchor: Offset.zero,
      angle: 0,
      alongLine: false,
      text: 'Nürnberg',
      iconName: null,
      sortKey: 0,
      properties: const {},
      geometryType: 'Point',
      featureId: null,
    ),
    screenAnchor: const Offset(180, 50),
    screenAngle: 0,
  );
  final painter = LabelPainter();
  final recorder = ui.PictureRecorder();
  painter.paint(
    canvas: Canvas(recorder),
    screenSize: const Size(360, 100),
    styleZoom: 12,
    symbols: [symbol],
    placementGeneration: 1,
    labelFadeDuration: Duration.zero,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(360, 100);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  painter.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bundled custom family changes actual place-label glyphs', () async {
    final loader = FontLoader('CustomRegressionFont')
      ..addFont(Future.value(ByteData.sublistView(
          await File('test/fixtures/custom-font.ttf').readAsBytes())));
    await loader.load();
    final fallback = await renderLabel('MissingRegressionFont');
    final custom = await renderLabel('CustomRegressionFont');
    expect(fallback.any((value) => value != 0), isTrue);
    expect(custom.any((value) => value != 0), isTrue);
    expect(custom, isNot(orderedEquals(fallback)));
  });
}
