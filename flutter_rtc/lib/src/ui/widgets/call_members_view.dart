import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/ui/widgets/connection_quality_indicator.dart';
import 'package:flutter_rtc/src/ui/widgets/video_box.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../context/model/member.dart';
import '../max_visible_grid_delegate.dart';

typedef MenuTapCallback = void Function(String memberId, String option);

class CallMembersView extends StatefulWidget {
  final List<Member> members;
  final Map<String, RTCVideoRenderer> renders;
  final Duration layoutTransitionDuration;
  final Curve layoutTransitionCurve;
  final MenuTapCallback? onMenuTap;
  final List<String> menuOptions;

  const CallMembersView({
    super.key,
    required this.members,
    required this.renders,
    this.layoutTransitionDuration = const Duration(milliseconds: 300),
    this.layoutTransitionCurve = Curves.easeInOut,
    this.onMenuTap,
    this.menuOptions = const ["mute", "info"]
  });

  @override
  State<CallMembersView> createState() => _CallMembersViewState();
}

class _CallMembersViewState extends State<CallMembersView> {
  late List<Member> _sortedMembers;
  String? _openMenuMemberId;

  void _toggleMenu(String memberId) {
    setState(() {
      // Open the selected menu; close if same tapped again
      _openMenuMemberId = _openMenuMemberId == memberId ? null : memberId;
    });
  }

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
      child: _buildGrid(key: ValueKey(_sortedMembers.map((m) => m.id).join(','))),
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
            isMenuOpen: _openMenuMemberId == member.id,
            onMenuToggle: _toggleMenu,
            menuOptions: widget.menuOptions,
            onMenuTap: (memberId, option) {
              _toggleMenu(memberId);
              widget.onMenuTap?.call(memberId, option);
            },
          ),
        );
      },
    );
  }
}

/// Single participant cell with inline menu.
class ParticipantGridCell extends StatelessWidget {
  final Member member;
  final RTCVideoRenderer? renderer;
  final bool isMenuOpen;
  final List<String> menuOptions;
  final ValueChanged<String> onMenuToggle;
  final MenuTapCallback onMenuTap;

  const ParticipantGridCell({
    super.key,
    required this.member,
    required this.isMenuOpen,
    required this.onMenuToggle,
    required this.onMenuTap,
    this.menuOptions = const [],
    this.renderer,
  });

  @override
  Widget build(BuildContext context) {
    final isMuted = !member.micEnabled;
    final isVideoOn = member.cameraEnabled;
    final isSpeaking = member.speakerEnable;

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
          // Video or avatar fills entire cell
          VideoBox(
            renderer: renderer,
            photoUrl: member.photoUrlOrId,
            available: isVideoOn,
            mirror: true,
          ),
          // Footer overlay
          _buildBar(isMuted, isVideoOn),
          ..._buildMenu(),
        ],
      ),
    );
  }

  Widget _buildBar(bool isMuted, bool isVideoOn) =>
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
      );


  List<Positioned> _buildMenu() {
    return [
      // Inline menu trigger
      Positioned(
        top: 16,
        left: 16,
        child: GestureDetector(
          onTap: () => onMenuToggle(member.id),
          child: const Icon(
            Icons.more_horiz,
            size: 16,
            color: Color.fromRGBO(255, 255, 255, 0.7),
          ),
        ),
      ),
      // Inline menu options
      if (isMenuOpen)
        Positioned(
          top: 32,
          left: 8,
          child: Material(
            color: const Color(0xFF2E2E2E),
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: menuOptions.map((option) =>
                  _InlineMenuItem(
                      label: option,
                      memberId: member.id,
                      onTap: onMenuTap
                  )).toList(),
            ),
          ),
        )
    ];
  }
}

/// Simple inline menu item.
class _InlineMenuItem extends StatelessWidget {
  final String label;
  final MenuTapCallback onTap;
  final String memberId;

  const _InlineMenuItem(
      {required this.label, required this.onTap, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(memberId, label),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
