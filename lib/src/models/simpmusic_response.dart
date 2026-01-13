/// Lyrics data model for SimpMusic API response.
class SimpMusicLyricsData {
  final String? id;
  final String? videoId;
  final String? title;
  final String? artist;
  final String? album;
  final int? duration;
  final String? syncedLyrics;
  final String? plainLyrics;
  final String? richSyncLyrics;
  final int? vote;

  const SimpMusicLyricsData({
    this.id,
    this.videoId,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.syncedLyrics,
    this.plainLyrics,
    this.richSyncLyrics,
    this.vote,
  });

  factory SimpMusicLyricsData.fromJson(Map<String, dynamic> json) {
    return SimpMusicLyricsData(
      id: json['id'] as String?,
      videoId: json['videoId'] as String?,
      title: json['songTitle'] as String?,
      artist: json['artistName'] as String?,
      album: json['albumName'] as String?,
      duration: json['durationSeconds'] as int?,
      syncedLyrics: json['syncedLyrics'] as String?,
      plainLyrics: json['plainLyric'] as String?,
      richSyncLyrics: json['richSyncLyrics'] as String?,
      vote: json['vote'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'videoId': videoId,
        'songTitle': title,
        'artistName': artist,
        'albumName': album,
        'durationSeconds': duration,
        'syncedLyrics': syncedLyrics,
        'plainLyric': plainLyrics,
        'richSyncLyrics': richSyncLyrics,
        'vote': vote,
      };

  /// Check if has any lyrics
  bool get hasLyrics => syncedLyrics != null || plainLyrics != null;

  /// Get the best available lyrics (prefer synced)
  String? get bestLyrics => syncedLyrics ?? plainLyrics;

  @override
  String toString() =>
      'SimpMusicLyricsData(id: $id, title: $title, artist: $artist)';
}

/// API response wrapper for SimpMusic API.
class SimpMusicApiResponse {
  final String? type;
  final List<SimpMusicLyricsData> data;

  const SimpMusicApiResponse({
    this.type,
    this.data = const [],
  });

  factory SimpMusicApiResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>?;
    return SimpMusicApiResponse(
      type: json['type'] as String?,
      data: dataList
              ?.map((e) =>
                  SimpMusicLyricsData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Check if request was successful
  bool get success => type == 'success';

  @override
  String toString() => 'SimpMusicApiResponse(type: $type, data: ${data.length} items)';
}
