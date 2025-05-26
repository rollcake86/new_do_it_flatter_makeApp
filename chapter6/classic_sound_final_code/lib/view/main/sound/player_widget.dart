import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:classicsound/data/local_database.dart';
import 'package:classicsound/data/music.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
class PlayerWidget extends StatefulWidget {
  final AudioPlayer player;
  final Music music;
  final Database database;
  final Function(Music) callback;

  const PlayerWidget({
    required this.player,
    Key? key,
    required this.music,
    required this.database,
    required this.callback,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;
  late Music _currentMusic;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;

  String get _durationText => _duration?.toString().split('.').first ?? '';
  String get _positionText => _position?.toString().split('.').first ?? '';

  AudioPlayer get _player => widget.player;

  bool _repeatCheck = false;
  bool _shuffleCheck = false;

  @override
  void initState() {
    super.initState();
    _currentMusic = widget.music;
    _playerState = _player.state; // 현재 플레이어 상태로 초기화
    _initStreams();
    // 초기 재생 시간 및 현재 위치 가져오기
    _player.getDuration().then((value) {
      if (mounted) setState(() => _duration = value);
    });
    _player.getCurrentPosition().then((value) {
      if (mounted) setState(() => _position = value);
    });
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Slider(
          onChanged: (v) {
            final position = v * (_duration?.inMilliseconds ?? 0);
            _player.seek(Duration(milliseconds: position.round()));
          },
          value: (_position != null &&
              _duration != null &&
              _duration!.inMilliseconds > 0 && // 재생 시간이 양수인지 확인
              _position!.inMilliseconds >= 0 && // 위치는 0이 될 수 있음
              _position!.inMilliseconds <= _duration!.inMilliseconds) // 위치는 전체 재생 시간과 같을 수 있음
              ? _position!.inMilliseconds / _duration!.inMilliseconds
              : 0.0,
        ),
        Text(
          _position != null
              ? '$_positionText / $_durationText'
              : _duration != null
              ? _durationText
              : '',
          style: const TextStyle(fontSize: 16.0),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('prev_button'),
              onPressed: _prev,
              iconSize: 44.0,
              icon: const Icon(Icons.skip_previous),
              color: color,
            ),
            IconButton(
              key: const Key('play_pause_button'), // 명확성을 위해 키 변경됨
              onPressed: _isPlaying ? _pause : _play, // 재생과 일시정지 간 전환
              iconSize: 44.0,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              color: color,
            ),
            // 중지 버튼 제거됨
            IconButton(
              key: const Key('next_button'),
              onPressed: _next,
              iconSize: 44.0,
              icon: const Icon(Icons.skip_next),
              color: color,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              key: const Key('repeat_button'),
              onPressed: _repeat,
              iconSize: 44.0,
              icon: const Icon(Icons.repeat),
              color: _repeatCheck ? Colors.amberAccent : color,
            ),
            IconButton(
              key: const Key('shuffle_button'),
              onPressed: _shuffle,
              iconSize: 44.0,
              icon: const Icon(Icons.shuffle),
              color: _shuffleCheck ? Colors.amberAccent : color,
            ),
          ],
        ),
      ],
    );
  }

  void _initStreams() {
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _positionSubscription = _player.onPositionChanged.listen(
          (p) => {if (mounted) setState(() => _position = p)},
    );

    _playerCompleteSubscription = _player.onPlayerComplete.listen((event) {
      _onCompletion();
    });

    _playerStateChangeSubscription =
        _player.onPlayerStateChanged.listen((state) {
          if (mounted) setState(() => _playerState = state);
        });
  }

  Future<void> _onCompletion() async {
    if (mounted) { // 위젯이 여전히 활성 상태인지 확인
      setState(() { // 반복 재생 시 종료 또는 초기화를 반영하도록 위치 업데이트
        _position = _repeatCheck ? Duration.zero : _duration; // 반복하지 않는 경우 _duration 사용
      });
    }
    if (_repeatCheck) {
      await _repeatPlay();
    } else {
      await _next();
    }
  }

  Future<void> _repeatPlay() async {
    final dir = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        _position = Duration.zero; // 반복 재생을 위해 위치 초기화
      });
    }
    final path = '${dir.path}/${_currentMusic.name}';
    await _player.setSourceDeviceFile(path); // 또는 play(DeviceFileSource(path)) 사용
    await _player.resume(); // 처음부터 재생 시작
  }

  Future<void> _play() async {
    final player = _player; // 편의를 위한 지역 변수
    final currentMusicPath = (await getApplicationDocumentsDirectory()).path + '/${_currentMusic.name}';

    try {
      if (player.state == PlayerState.paused) {
        await player.resume();
      } else {
        await player.play(DeviceFileSource(currentMusicPath), position: _position);
      }
      if (mounted) {
        setState(() => _playerState = PlayerState.playing); // 즉각적인 UI 피드백
      }
    } catch (e) {
      print("오디오 재생 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('재생 오류: ${e.toString()}')),
        );
        setState(() => _playerState = PlayerState.stopped); // 또는 다른 오류 상태
      }
    }
  }

  Future<void> _pause() async {
    try {
      await _player.pause();
      if (mounted) {
        setState(() => _playerState = PlayerState.paused); // 즉각적인 UI 피드백
      }
    } catch (e) {
      print("오디오 일시정지 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일시정지 오류: ${e.toString()}')),
        );
      }
    }
  }

  void _repeat() {
    if (mounted) setState(() => _repeatCheck = !_repeatCheck);
  }

  void _shuffle() {
    if (mounted) setState(() => _shuffleCheck = !_shuffleCheck);
  }

  Future<void> _prev() async {
    if(!mounted) return; // 위젯이 여전히 마운트되어 있는지 확인

    final musics = await MusicDatabase(widget.database).getMusic();
    int currentIndex = musics.indexWhere((m) => m['name'] == _currentMusic.name); // _currentMusic 사용

    if (currentIndex > 0) {
      await _playMusic(musics[currentIndex - 1]);
    } else if (currentIndex == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('첫 번째 곡입니다.')));
    } else {
      // 현재 음악을 목록에서 찾을 수 없음. 첫 번째 곡을 재생하거나 오류 처리
      if (musics.isNotEmpty) await _playMusic(musics.first);
    }
  }

  Future<void> _next() async {
    if(!mounted) return; // 위젯이 여전히 마운트되어 있는지 확인

    final List<Map<String, dynamic>> musics = await MusicDatabase(widget.database).getMusic();
    List<Map<String, dynamic>> playlist = List.from(musics); // 셔플을 위한 변경 가능한 복사본 생성

    if (_shuffleCheck) {
      playlist.shuffle();
      int currentShuffledIndex = playlist.indexWhere((m) => m['name'] == _currentMusic.name);
      if (currentShuffledIndex != -1 && currentShuffledIndex + 1 < playlist.length) {
        await _playMusic(playlist[currentShuffledIndex + 1]);
      } else if (playlist.isNotEmpty && playlist.first['name'] != _currentMusic.name) {
        await _playMusic(playlist.first);
      } else if (playlist.length > 1) { // 현재 곡이 첫 번째이고 셔플 후 남은 곡이 하나뿐인 경우의 대체 처리
        await _playMusic(playlist[1]);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('마지막 곡입니다.')));
      }
      return;
    }
    // 셔플 비활성화 로직
    int currentIndex = playlist.indexWhere((m) => m['name'] == _currentMusic.name); // _currentMusic 사용

    if (currentIndex != -1 && currentIndex + 1 < playlist.length) {
      await _playMusic(playlist[currentIndex + 1]);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('마지막 곡입니다.')));
    }
  }

  Future<void> _playMusic(Map<String, dynamic> musicData) async {
    if(!mounted) return; // 위젯이 여전히 마운트되어 있는지 확인

    final dir = await getApplicationDocumentsDirectory();
    _currentMusic = Music(
      musicData['name'],
      musicData['composer'],
      musicData['tag'],
      musicData['category'],
      musicData['size'],
      musicData['type'],
      musicData['downloadUrl'],
      musicData['imageDownloadUrl'],
    );
    final path = '${dir.path}/${_currentMusic.name}';

    try {
      await _player.play(DeviceFileSource(path)); // play()를 사용하여 음원을 설정하고 재생 시작
      if (mounted) {
        widget.callback(_currentMusic);
        setState(() {
          _position = Duration.zero; // 새 곡을 위해 현재 위치 초기화
        });
        _player.getDuration().then((value) {
          if (mounted) setState(() => _duration = value);
        });
      }
    } catch (e) {
      print("음악 재생 오류 (_playMusic): $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다음 곡 로딩 오류: ${e.toString()}')),
        );
        setState(() => _playerState = PlayerState.stopped);
      }
    }
  }
}