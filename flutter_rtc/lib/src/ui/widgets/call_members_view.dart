import 'package:flutter/material.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _buildMedia(context)),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                member.displayNameOrId,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 4.0,
                        color: Colors.black,
                        offset: Offset(1, 1))
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (_) =>
              const [
                PopupMenuItem(value: 'settings', child: Text('Configuración')),
                PopupMenuItem(value: 'info', child: Text('Información')),
              ],
              onSelected: (value) {},
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConnectionQualityIndicator(quality: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    if (member.cameraEnabled && renderer != null) {
      return videoBuilder?.call(context, member, renderer) ??
          Transform.scale(scale: -1.0, child: RTCVideoView(renderer!));
    }
    return avatarBuilder?.call(context, member) ??
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(member.photoUrlOrId),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Text(
              member.displayNameOrId[0].toUpperCase(),
              style: const TextStyle(color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
  }
}

class ConnectionQualityIndicator extends StatelessWidget {
  final double quality;

  const ConnectionQualityIndicator({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < quality;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
