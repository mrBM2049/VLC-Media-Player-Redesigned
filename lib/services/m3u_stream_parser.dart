import 'dart:convert';
import 'dart:io';

/// Domain model representing an IPTV or Web Network Stream Channel.
class NetworkStreamChannel {
  final String id;
  final String name;
  final String streamUrl;
  final String group; // e.g. News, Sports, Music, Science & Tech, Movies & TV
  final String? logoUrl;
  final String? tvgId;
  final String resolution; // e.g. '1080p', '720p', '4K'
  final String country;

  const NetworkStreamChannel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.group = 'General',
    this.logoUrl,
    this.tvgId,
    this.resolution = '1080p',
    this.country = 'Global',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stream_url': streamUrl,
      'group': group,
      'logo_url': logoUrl,
      'tvg_id': tvgId,
      'resolution': resolution,
      'country': country,
    };
  }

  factory NetworkStreamChannel.fromMap(Map<String, dynamic> map) {
    return NetworkStreamChannel(
      id: map['id'] as String,
      name: map['name'] as String,
      streamUrl: map['stream_url'] as String,
      group: map['group'] as String? ?? 'General',
      logoUrl: map['logo_url'] as String?,
      tvgId: map['tvg_id'] as String?,
      resolution: map['resolution'] as String? ?? '1080p',
      country: map['country'] as String? ?? 'Global',
    );
  }
}

/// Robust parser for `.m3u` and `.m3u8` IPTV and web radio playlists.
class M3uStreamParser {
  /// Default curated public free legal IPTV streams.
  static const List<NetworkStreamChannel> defaultCuratedStreams = [
    NetworkStreamChannel(
      id: 'nasa_tv',
      name: 'NASA TV Live (Official)',
      streamUrl: 'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
      group: 'Science & Tech',
      resolution: '1080p60',
      country: 'USA',
    ),
    NetworkStreamChannel(
      id: 'bloomberg_tv',
      name: 'Bloomberg Global Live',
      streamUrl: 'https://liveproduction.global.ssl.fastly.net/us/index.m3u8',
      group: 'News',
      resolution: '1080p',
      country: 'Global',
    ),
    NetworkStreamChannel(
      id: 'redbull_tv',
      name: 'Red Bull TV Extreme Sports',
      streamUrl: 'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
      group: 'Sports',
      resolution: '1080p60',
      country: 'Global',
    ),
    NetworkStreamChannel(
      id: 'euronews_en',
      name: 'Euronews English Live',
      streamUrl: 'https://euronews-euronews-world-1-nl.samsung.wurl.tv/playlist.m3u8',
      group: 'News',
      resolution: '720p',
      country: 'Europe',
    ),
    NetworkStreamChannel(
      id: 'blender_stream',
      name: 'Blender Studio Master HLS',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      group: 'Movies & TV',
      resolution: '1080p',
      country: 'Global',
    ),
    NetworkStreamChannel(
      id: 'somafm_groove',
      name: 'SomaFM Groove Salad (Ambient)',
      streamUrl: 'https://ice1.somafm.com/groovesalad-128-mp3',
      group: 'Music',
      resolution: 'Audio 320k',
      country: 'USA',
    ),
  ];

  /// Parses an M3U/M3U8 string content into a list of [NetworkStreamChannel].
  static List<NetworkStreamChannel> parse(String content) {
    final List<NetworkStreamChannel> channels = [];
    final lines = const LineSplitter().convert(content);

    String? currentName;
    String? currentGroup;
    String? currentLogo;
    String? currentTvgId;
    String currentResolution = '1080p';

    final extInfRegex = RegExp(r'^#EXTINF:(?:-?\d+)?\s*(.*)$', caseSensitive: false);
    final groupRegex = RegExp(r'group-title="([^"]*)"', caseSensitive: false);
    final logoRegex = RegExp(r'tvg-logo="([^"]*)"', caseSensitive: false);
    final idRegex = RegExp(r'tvg-id="([^"]*)"', caseSensitive: false);
    final resRegex = RegExp(r'(\d{3,4}[piP]|4K|UHD)', caseSensitive: false);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        final match = extInfRegex.firstMatch(line);
        if (match != null) {
          final rawAttributes = match.group(1) ?? '';

          // Extract group-title
          final groupMatch = groupRegex.firstMatch(rawAttributes);
          if (groupMatch != null) {
            currentGroup = groupMatch.group(1);
          }

          // Extract tvg-logo
          final logoMatch = logoRegex.firstMatch(rawAttributes);
          if (logoMatch != null) {
            currentLogo = logoMatch.group(1);
          }

          // Extract tvg-id
          final idMatch = idRegex.firstMatch(rawAttributes);
          if (idMatch != null) {
            currentTvgId = idMatch.group(1);
          }

          // Extract channel title after last comma
          final commaIdx = rawAttributes.lastIndexOf(',');
          if (commaIdx != -1 && commaIdx < rawAttributes.length - 1) {
            currentName = rawAttributes.substring(commaIdx + 1).trim();
          } else {
            currentName = 'Stream Channel ${channels.length + 1}';
          }

          // Detect resolution if mentioned in title or attributes
          final resMatch = resRegex.firstMatch(rawAttributes);
          if (resMatch != null) {
            currentResolution = resMatch.group(1)!.toUpperCase();
          }
        }
      } else if (!line.startsWith('#') && (line.startsWith('http://') || line.startsWith('https://') || line.startsWith('rtsp://') || line.startsWith('rtmp://') || line.startsWith('mms://'))) {
        // Stream URL line
        final streamUrl = line;
        final channelId = currentTvgId ?? 'stream_${channels.length + 1}_${DateTime.now().microsecondsSinceEpoch}';
        final channelName = currentName ?? 'Channel ${channels.length + 1}';

        channels.add(NetworkStreamChannel(
          id: channelId,
          name: channelName,
          streamUrl: streamUrl,
          group: currentGroup?.isNotEmpty == true ? currentGroup! : 'General',
          logoUrl: currentLogo,
          tvgId: currentTvgId,
          resolution: currentResolution,
        ));

        // Reset state for next channel
        currentName = null;
        currentGroup = null;
        currentLogo = null;
        currentTvgId = null;
        currentResolution = '1080p';
      }
    }

    return channels;
  }

  /// Parses an M3U / M3U8 file from the local filesystem.
  static Future<List<NetworkStreamChannel>> parseFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return [];
    final content = await file.readAsString();
    return parse(content);
  }
}
