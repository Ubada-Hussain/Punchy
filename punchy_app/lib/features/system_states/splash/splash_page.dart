import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'splash_handoff.dart';
import 'splash_stage.dart';
import 'splash_timings.dart';
import 'splash_wordmark.dart';

enum _Phase { intro, holding, loadingFade, exiting }

class PunchyIntroPage extends StatefulWidget {
  const PunchyIntroPage({
    super.key,
    required this.initialization,
    required this.onReady,
  });

  final Future<void> initialization;
  final VoidCallback onReady;

  @override
  State<PunchyIntroPage> createState() => _PunchyIntroPageState();
}

class _PunchyIntroPageState extends State<PunchyIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final SplashHandoff _handoff;
  Timer? _loadingTimer;
  _Phase _phase = _Phase.intro;
  bool? _reducedMotion;
  bool _showLoading = false;
  bool _loadingDue = false;
  double _loadingAtExit = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_completed);
    _handoff = SplashHandoff(widget.initialization, _exit);
    _loadingTimer = Timer(SplashTimings.loadingThreshold, () {
      if (!mounted || _handoff.initialized || _phase == _Phase.exiting) return;
      _loadingDue = true;
      _showLoadingHint();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotion != null) return;
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _play(_reducedMotion! ? SplashTimings.reducedIntro : SplashTimings.intro);
  }

  void _play(Duration duration) {
    _controller.duration = duration;
    _controller.forward(from: 0);
  }

  void _showLoadingHint() {
    // A backgrounded/muted intro must finish before reusing its controller.
    if (_phase != _Phase.holding || _handoff.initialized) return;
    setState(() {
      _showLoading = true;
      _phase = _Phase.loadingFade;
    });
    _play(SplashTimings.loadingFade);
  }

  void _completed(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    switch (_phase) {
      case _Phase.intro:
        setState(() => _phase = _Phase.holding);
        _handoff.animationFinished();
        if (_loadingDue) _showLoadingHint();
      case _Phase.exiting:
        widget.onReady();
      case _Phase.holding:
      case _Phase.loadingFade:
        break;
    }
  }

  void _exit() {
    if (!mounted) return;
    _loadingTimer?.cancel();
    _loadingAtExit = _showLoading ? _controller.value : 0;
    setState(() => _phase = _Phase.exiting);
    _play(SplashTimings.exit);
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _handoff.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: MediaQuery.withNoTextScaling(
      child: Semantics(
        label: 'Punchy, the ultimate loyalty app',
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final reduced = _reducedMotion ?? false;
              final time = _phase == _Phase.intro ? _controller.value : 1.0;
              final opacity = _phase == _Phase.exiting
                  ? 1 - _controller.value
                  : (reduced && _phase == _Phase.intro
                        ? _controller.value
                        : 1.0);
              final loadingOpacity = _phase == _Phase.exiting
                  ? _loadingAtExit
                  : (_showLoading ? _controller.value : 0.0);
              return Opacity(
                opacity: opacity,
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -40),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SplashStage(time: time, reducedMotion: reduced),
                          const SizedBox(height: 34),
                          SplashWordmark(time: time, reducedMotion: reduced),
                          const SizedBox(height: 10),
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              SplashTagline(time: time, reducedMotion: reduced),
                              if (_showLoading)
                                Positioned(
                                  top: 32,
                                  child: Opacity(
                                    opacity: loadingOpacity,
                                    child: Text(
                                      'Still loading...',
                                      style: GoogleFonts.dmSans(
                                        color: SplashColors.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
