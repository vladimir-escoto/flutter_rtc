import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/ui/widgets/connection_quality_indicator.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../context/model/member.dart';
import '../max_visible_grid_delegate.dart';

class CallMembersView extends StatefulWidget {
  final List<Member> members;
  final Map<String, RTCVideoRenderer> renders;
  final Widget Function(BuildContext, Member)? avatarBuilder;
  final Widget Function(BuildContext, Member, RTCVideoRenderer?)? videoBuilder;
  final Duration layoutTransitionDuration;
  final Curve layoutTransitionCurve;

  const CallMembersView({
    super.key,
    required this.members,
    required this.renders,
    this.avatarBuilder,
    this.videoBuilder,
    this.layoutTransitionDuration = const Duration(milliseconds: 300),
    this.layoutTransitionCurve = Curves.easeInOut,
  });

  @override
  State<CallMembersView> createState() => _CallMembersViewState();
}

class _CallMembersViewState extends State<CallMembersView> {
  late List<Member> _sortedMembers;

  @override
  void initState() {
    super.initState();
    _updateMembers();
  }

  @override
  void didUpdateWidget(covariant CallMembersView old) {
    super.didUpdateWidget(old);
    if (!_listEquals(widget.members, old.members)) {
      _updateMembers();
    }
  }

  bool _listEquals(List<Member> a, List<Member> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].cameraEnabled != b[i].cameraEnabled) return false;
    }
    return true;
  }

  void _updateMembers() {
    _sortedMembers = [...widget.members]
      ..sort((a, b) => (b.cameraEnabled ? 1 : 0).compareTo(a.cameraEnabled ? 1 : 0));
  }

  @override
  Widget build(BuildContext context) {
    if (_sortedMembers.isEmpty) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: widget.layoutTransitionDuration,
      switchInCurve: widget.layoutTransitionCurve,
      child: _buildGrid(
        key: ValueKey(_sortedMembers.map((m) => m.id).join(',')),
      ),
    );
  }

  Widget _buildGrid({required Key key}) {
    return GridView.builder(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: MaxVisibleGridDelegate(
        itemCount: _sortedMembers.length,
        crossAxisCountResolver: (itemCount, isPortrait) {
          if (isPortrait) return itemCount < 4 ? 1 : 2;
          if (itemCount == 1) return 1;
          if (itemCount == 2) return 2;
          if (itemCount == 3) return 3;
          if (itemCount == 4) return 2;
          if (itemCount <= 6) return 3;
          return 4;
        },
        maxRowsPortrait: 4,
        maxRowsLandscape: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _sortedMembers.length,
      itemBuilder: (context, index) {
        final member = _sortedMembers[index];
        return AnimatedSwitcher(
          duration: widget.layoutTransitionDuration,
          switchInCurve: widget.layoutTransitionCurve,
          child: ParticipantGridCell(
            key: ValueKey(member.id),
            member: member,
            renderer: widget.renders[member.id],
            avatarBuilder: widget.avatarBuilder,
            videoBuilder: widget.videoBuilder,
          ),
        );
      },
    );
  }
}

class ParticipantGridCell extends StatelessWidget {
  final Member member;
  final RTCVideoRenderer? renderer;
  final Widget Function(BuildContext, Member)? avatarBuilder;
  final Widget Function(BuildContext, Member, RTCVideoRenderer?)? videoBuilder;

  const ParticipantGridCell({
    super.key,
    required this.member,
    this.renderer,
    this.avatarBuilder,
    this.videoBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMuted = !member.micEnabled;
    final bool isVideoOn = member.cameraEnabled;
    final bool isSpeaking = member.speakerEnable;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: isSpeaking
            ? Border.all(color: const Color(0xFF3B82F6), width: 2)
            : null,
      ),
      child: Stack(
        children: [
          // Media (video full or avatar fill)
          Positioned.fill(
            child: isVideoOn && renderer != null
                ? videoBuilder?.call(context, member, renderer) ??
                RTCVideoView(renderer!, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                : avatarBuilder?.call(context, member) ??
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(member.photoUrlOrId),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          ),
          // Footer overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nombre
                  Expanded(
                    child: Text(
                      member.displayNameOrId,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Sans-serif',
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Iconos de estado
                  Row(
                    children: [
                      Icon(
                        isMuted ? Icons.mic_off : Icons.mic,
                        size: 16,
                        color: isMuted ? Colors.red : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isVideoOn ? Icons.videocam : Icons.videocam_off,
                        size: 16,
                        color: isVideoOn ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      ConnectionQualityIndicator(
                        quality: member.connectionQuality,
                        barCount: 4,
                        activeColor: const Color(0xFF22C55E),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Menú de acciones
          Positioned(
            top: 8,
            left: 8,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.more_horiz,
                size: 16,
                color: Color.fromRGBO(255, 255, 255, 0.7),
              ),
              onSelected: (value) {
                // acciones
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'mute', child: Text('Mute')),
                const PopupMenuItem(value: 'settings', child: Text('Settings')),
                const PopupMenuItem(value: 'info', child: Text('Info')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildDefaultAvatar(Member member) {
  //   return Container(
  //     color: Colors.grey,
  //     child: Center(
  //       child: Text(
  //         member.displayNameOrId[0].toUpperCase(),
  //         style: const TextStyle(
  //           color: Colors.white,
  //           fontSize: 24,
  //           fontWeight: FontWeight.bold,
  //           fontFamily: 'Sans-serif',
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

