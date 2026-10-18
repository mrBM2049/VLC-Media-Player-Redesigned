import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/services/m3u_stream_parser.dart';

void main() {
  group('M3uStreamParser Tests', () {
    test('Default curated streams list is populated and valid', () {
      final defaultList = M3uStreamParser.defaultCuratedStreams;
      expect(defaultList.length, greaterThanOrEqualTo(5));

      final nasa = defaultList.firstWhere((s) => s.id == 'nasa_tv');
      expect(nasa.name, contains('NASA TV'));
      expect(nasa.group, equals('Science & Tech'));
      expect(nasa.streamUrl, endsWith('.m3u8'));
    });

    test('Parses standard EXTINF M3U playlist format cleanly', () {
      const m3uSample = '''
#EXTM3U
#EXTINF:-1 tvg-id="Test1.id" tvg-name="Channel One" tvg-logo="https://logo.png" group-title="News",News 24/7 (1080p)
https://streams.example.com/live/news1080.m3u8
#EXTINF:-1 tvg-id="Sports.id" group-title="Sports",Live Extreme Sports (720p)
https://streams.example.com/live/sports720.m3u8
#EXTINF:-1 group-title="Music",Lo-Fi Beats Live
http://icecast.example.com/lofi.mp3
''';

      final channels = M3uStreamParser.parse(m3uSample);
      expect(channels.length, equals(3));

      // Channel 1
      expect(channels[0].name, equals('News 24/7 (1080p)'));
      expect(channels[0].group, equals('News'));
      expect(channels[0].tvgId, equals('Test1.id'));
      expect(channels[0].logoUrl, equals('https://logo.png'));
      expect(channels[0].streamUrl, equals('https://streams.example.com/live/news1080.m3u8'));
      expect(channels[0].resolution, equals('1080P'));

      // Channel 2
      expect(channels[1].name, equals('Live Extreme Sports (720p)'));
      expect(channels[1].group, equals('Sports'));
      expect(channels[1].streamUrl, equals('https://streams.example.com/live/sports720.m3u8'));
      expect(channels[1].resolution, equals('720P'));

      // Channel 3
      expect(channels[2].name, equals('Lo-Fi Beats Live'));
      expect(channels[2].group, equals('Music'));
      expect(channels[2].streamUrl, equals('http://icecast.example.com/lofi.mp3'));
    });

    test('Parses M3U file from disk asynchronously', () async {
      final tempDir = Directory.systemTemp.createTempSync('vlc_m3u_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final file = File('${tempDir.path}/test_channels.m3u');
      await file.writeAsString('''
#EXTM3U
#EXTINF:-1 group-title="Movies",Blender Sci-Fi Channel
https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8
''');

      final channels = await M3uStreamParser.parseFile(file.path);
      expect(channels.length, equals(1));
      expect(channels.first.name, equals('Blender Sci-Fi Channel'));
      expect(channels.first.group, equals('Movies'));
      expect(channels.first.streamUrl, contains('mux.dev'));
    });

    test('NetworkStreamChannel toMap and fromMap serialization', () {
      const channel = NetworkStreamChannel(
        id: 'ch_test',
        name: 'Test Stream',
        streamUrl: 'https://test.m3u8',
        group: 'Tech',
        logoUrl: 'https://logo.png',
        tvgId: 'test_tvg',
        resolution: '4K',
        country: 'Global',
      );

      final map = channel.toMap();
      final reconstructed = NetworkStreamChannel.fromMap(map);

      expect(reconstructed.id, equals(channel.id));
      expect(reconstructed.name, equals(channel.name));
      expect(reconstructed.streamUrl, equals(channel.streamUrl));
      expect(reconstructed.group, equals(channel.group));
      expect(reconstructed.resolution, equals(channel.resolution));
    });
  });
}

