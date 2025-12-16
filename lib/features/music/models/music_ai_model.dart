class ChordEvent {
  final Duration timestamp;
  final String name;
  ChordEvent({required this.timestamp, required this.name});
}

class BeatEvent {
  final Duration timestamp;
  final bool isDownbeat;
  BeatEvent({required this.timestamp, required this.isDownbeat});
}

class MusicStructure {
  final String label; // Intro, Verse, Chorus
  final Duration start;
  final Duration end;
  MusicStructure({required this.label, required this.start, required this.end});
}

class AnalysisResult {
  final List<ChordEvent> chords;
  final List<BeatEvent> beats;
  final List<MusicStructure> structure;
  final double bpm;
  final String key;

  AnalysisResult(
      {required this.chords,
      required this.beats,
      required this.structure,
      this.bpm = 120.0,
      this.key = "C Major"});
}

// --- NEW CLASS ADDED ---
class GeneratedMusic {
  final String? title;
  final String? imageUrl;
  final String? audioUrl;

  GeneratedMusic({this.title, this.imageUrl, this.audioUrl});
}

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final Duration duration;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    this.duration = Duration.zero,
  });
}

class LyricLine {
  final String text;
  final Duration timestamp;
  final String? translation;

  LyricLine({
    required this.text, 
    required this.timestamp, 
    this.translation
  });
}