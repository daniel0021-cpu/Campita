import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web/web.dart' as web;
import '../theme/app_theme.dart';

class MusicPlayerSheet extends StatefulWidget {
  final VoidCallback? onClose;

  const MusicPlayerSheet({
    super.key,
    this.onClose,
  });

  @override
  State<MusicPlayerSheet> createState() => _MusicPlayerSheetState();
}

class _MusicPlayerSheetState extends State<MusicPlayerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  web.HTMLAudioElement? _audioElement;
  
  bool _isExpanded = false;
  bool _isPlaying = false;
  bool _isSearching = false;
  bool _isLoading = false;
  
  String? _currentTrack;
  String? _currentArtist;
  String? _currentArtworkUrl;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _artistSuggestions = [];

  static const double maxVolume = 0.4; // 40% max volume

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _initAudio();
  }

  void _initAudio() {
    _audioElement = web.HTMLAudioElement();
    _audioElement!.volume = maxVolume;
    
    // Listen to time updates
    _audioElement!.onTimeUpdate.listen((_) {
      if (mounted && _audioElement != null) {
        setState(() {
          _currentPosition = Duration(
            seconds: _audioElement!.currentTime.toInt(),
          );
        });
      }
    });
    
    // Listen to duration changes
    _audioElement!.onLoadedMetadata.listen((_) {
      if (mounted && _audioElement != null) {
        setState(() {
          _totalDuration = Duration(
            seconds: _audioElement!.duration.toInt(),
          );
        });
      }
    });
    
    // Listen to ended event - auto play next song
    _audioElement!.onEnded.listen((_) {
      if (mounted) {
        setState(() => _isPlaying = false);
        // Auto-play next song if available
        _playNextSong();
      }
    });
  }
  
  void _playNextSong() {
    if (_searchResults.isEmpty) return;
    
    // Find current track index
    final currentIndex = _searchResults.indexWhere(
      (track) => track['name'] == _currentTrack,
    );
    
    if (currentIndex >= 0 && currentIndex < _searchResults.length - 1) {
      // Play next track
      final nextTrack = _searchResults[currentIndex + 1];
      debugPrint('🎵 Auto-playing next track: ${nextTrack['name']}');
      _playTrack(nextTrack);
    } else {
      debugPrint('🎵 End of playlist');
    }
  }

  @override
  void dispose() {
    _audioElement?.pause();
    _audioElement = null;
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMusic(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      // Using iTunes Search API (free, no auth required)
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=song&limit=20',
      );
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List).map((item) {
          return {
            'name': item['trackName'] ?? '',
            'artist': item['artistName'] ?? '',
            'album': item['collectionName'] ?? '',
            'artwork': (item['artworkUrl100'] as String?)?.replaceAll('100x100', '300x300') ?? '',
            'preview': item['previewUrl'] ?? '',
            'duration': item['trackTimeMillis'] ?? 0,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _searchResults = results;
            _artistSuggestions = _extractArtists(results);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Music search error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _extractArtists(List<Map<String, dynamic>> results) {
    final artistMap = <String, Map<String, dynamic>>{};
    
    for (final track in results) {
      final artist = track['artist'] as String;
      if (!artistMap.containsKey(artist)) {
        artistMap[artist] = {
          'name': artist,
          'artwork': track['artwork'],
          'tracks': 1,
        };
      } else {
        artistMap[artist]!['tracks'] = (artistMap[artist]!['tracks'] as int) + 1;
      }
    }
    
    return artistMap.values.toList()
      ..sort((a, b) => (b['tracks'] as int).compareTo(a['tracks'] as int));
  }

  void _playTrack(Map<String, dynamic> track) {
    final previewUrl = track['preview'] as String;
    if (previewUrl.isEmpty) {
      debugPrint('❌ No preview URL for track: ${track['name']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No preview available for this track'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    debugPrint('🎵 Playing track: ${track['name']} - $previewUrl');
    
    try {
      // Stop current playback
      _audioElement?.pause();
      _audioElement?.currentTime = 0;
      
      // Set new source
      _audioElement?.src = previewUrl;
      _audioElement?.crossOrigin = 'anonymous';
      
      setState(() {
        _currentTrack = track['name'];
        _currentArtist = track['artist'];
        _currentArtworkUrl = track['artwork'];
        _isPlaying = false; // Set to false initially
        _currentPosition = Duration.zero;
      });
      
      // Load and play
      _audioElement?.load();
      
      // Wait for loaded data before playing
      _audioElement?.onLoadedData.first.then((_) {
        debugPrint('✅ Audio loaded, attempting to play...');
        try {
          _audioElement?.play();
          debugPrint('✅ Play command sent');
          // Give it a moment to start playing
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() => _isPlaying = true);
            }
          });
        } catch (error) {
          debugPrint('❌ Play error: $error');
          if (mounted) {
            setState(() => _isPlaying = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not play audio. Try another track.'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }).catchError((error) {
        debugPrint('❌ Load error: $error');
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });
      
    } catch (e) {
      debugPrint('❌ Error playing track: $e');
      if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing track: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _togglePlayPause() {
    if (_audioElement == null) return;

    if (_isPlaying) {
      _audioElement!.pause();
      setState(() => _isPlaying = false);
    } else {
      _audioElement!.play();
      setState(() => _isPlaying = true);
    }
  }

  void stopMusic() {
    _audioElement?.pause();
    setState(() {
      _isPlaying = false;
      _currentPosition = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (value * 0.5),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!_isExpanded) {
            setState(() => _isExpanded = true);
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: _isExpanded
              ? _buildExpandedSheet(isDark)
              : _buildCollapsedButton(isDark),
        ),
      ),
    );
  }

  Widget _buildCollapsedButton(bool isDark) {
    return Material(
      key: const ValueKey('collapsed'),
      elevation: 8,
      shape: const CircleBorder(),
      shadowColor: AppColors.primary.withAlpha(128),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withAlpha(204),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing effect when playing
            if (_isPlaying)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Container(
                    width: 60 + (value * 10),
                    height: 60 + (value * 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withAlpha((255 * (1 - value)).toInt()),
                        width: 2,
                      ),
                    ),
                  );
                },
                onEnd: () {
                  if (_isPlaying && mounted) {
                    setState(() {});
                  }
                },
              ),
            Icon(
              _isPlaying ? Icons.music_note_rounded : Icons.music_note_outlined,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSheet(bool isDark) {
    return Material(
      elevation: 24,
      borderRadius: BorderRadius.circular(32),
      shadowColor: AppColors.primary.withAlpha(77),
      child: Container(
        key: const ValueKey('expanded'),
        width: MediaQuery.of(context).size.width - 32,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkCard,
                    AppColors.darkCard.withAlpha(242),
                  ]
                : [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(13)
                : Colors.black.withAlpha(13),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            children: [
              // Header with close button
              _buildHeader(isDark),
              
              // Search bar
              _buildSearchBar(isDark),
              
              // Content area
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _isSearching
                      ? _buildSearchResults(isDark)
                      : _buildNowPlaying(isDark),
                ),
              ),
              
              // Mini player at bottom
              if (_currentTrack != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildMiniPlayer(isDark),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withAlpha(179),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Music Player',
              style: GoogleFonts.notoSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkGrey,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white : AppColors.darkGrey,
            ),
            onPressed: () {
              setState(() => _isExpanded = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (value * 0.1),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.grey[850]!.withAlpha(179),
                      Colors.grey[800]!.withAlpha(179),
                    ]
                  : [
                      AppColors.primary.withAlpha(26),
                      AppColors.primary.withAlpha(13),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(26)
                  : AppColors.primary.withAlpha(51),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(26),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onSubmitted: _searchMusic,
                  onChanged: (value) {
                    setState(() {}); // Rebuild to show/hide buttons
                  },
                  style: GoogleFonts.notoSans(
                    color: isDark ? Colors.white : AppColors.darkGrey,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: '🎵 Search any song in the world...',
                    hintStyle: GoogleFonts.notoSans(
                      color: isDark ? Colors.white60 : AppColors.grey,
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: isDark ? Colors.white60 : AppColors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _isSearching = false;
                                    _searchResults = [];
                                    _artistSuggestions = [];
                                  });
                                },
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withAlpha(204),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _searchMusic(_searchController.text),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.search_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Search',
                                            style: GoogleFonts.notoSans(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching for music...',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: isDark ? Colors.white60 : AppColors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artist suggestions with animation
          if (_artistSuggestions.isNotEmpty) ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Artists',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _artistSuggestions.length,
                      itemBuilder: (context, index) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: _buildArtistCard(_artistSuggestions[index], isDark),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
          
          // Track results with staggered animation
          if (_searchResults.isNotEmpty) ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Songs',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._searchResults.asMap().entries.map((entry) {
                    final index = entry.key;
                    final track = entry.value;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 30)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(30 * (1 - value), 0),
                            child: child,
                          ),
                        );
                      },
                      child: _buildTrackTile(track, isDark),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> artist, bool isDark) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: artist['artwork'] != null
                  ? DecorationImage(
                      image: NetworkImage(artist['artwork']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: AppColors.primary.withAlpha(51),
            ),
            child: artist['artwork'] == null
                ? Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 32,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            artist['name'],
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.darkGrey,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(Map<String, dynamic> track, bool isDark) {
    final isCurrentTrack = track['name'] == _currentTrack;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentTrack
            ? AppColors.primary.withAlpha(26)
            : isDark
                ? Colors.grey[850]?.withAlpha(77)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: track['artwork'] != null && track['artwork'].isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(track['artwork']),
                    fit: BoxFit.cover,
                  )
                : null,
            color: AppColors.primary.withAlpha(51),
          ),
          child: track['artwork'] == null || track['artwork'].isEmpty
              ? Icon(
                  Icons.music_note_rounded,
                  color: AppColors.primary,
                )
              : null,
        ),
        title: Text(
          track['name'],
          style: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isCurrentTrack
                ? AppColors.primary
                : isDark
                    ? Colors.white
                    : AppColors.darkGrey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track['artist'],
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: isDark ? Colors.white60 : AppColors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isCurrentTrack && _isPlaying
            ? const Icon(
                Icons.volume_up_rounded,
                color: AppColors.primary,
                size: 20,
              )
            : null,
        onTap: () => _playTrack(track),
      ),
    );
  }

  Widget _buildNowPlaying(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(51),
                      AppColors.primary.withAlpha(26),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.library_music_rounded,
                  size: 60,
                  color: AppColors.primary.withAlpha(179),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '🎵 Search Any Song',
              style: GoogleFonts.notoSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Find millions of songs from around the world',
              style: GoogleFonts.notoSans(
                fontSize: 15,
                color: isDark ? Colors.white70 : AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withAlpha(51),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '30-second previews • Auto-plays next',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type artist, song, or album name above',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: isDark ? Colors.white.withAlpha(128) : AppColors.grey.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Popular suggestions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'Drake',
                'The Weeknd',
                'Ed Sheeran',
                'Ariana Grande',
                'Taylor Swift',
              ].map((artist) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _searchController.text = artist;
                      _searchMusic(artist);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]?.withAlpha(128)
                            : AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(51),
                        ),
                      ),
                      child: Text(
                        artist,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[900]?.withAlpha(242)
            : AppColors.primary.withAlpha(13),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.grey[800]!
                : AppColors.primary.withAlpha(26),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentArtworkUrl != null)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(_currentArtworkUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTrack ?? '',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.darkGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _currentArtist ?? '',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : AppColors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
                onPressed: _togglePlayPause,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : AppColors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: _totalDuration.inSeconds > 0
                      ? _currentPosition.inSeconds / _totalDuration.inSeconds
                      : 0.0,
                  backgroundColor: isDark
                      ? Colors.grey[800]
                      : AppColors.grey.withAlpha(51),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_totalDuration),
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : AppColors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
