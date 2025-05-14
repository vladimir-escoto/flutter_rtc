import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
  final _heroTags = <String>{};

  @override
  void initState() {
    super.initState();
    _updateMembers();
  }

  @override
  void didUpdateWidget(covariant CallMembersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(widget.members, oldWidget.members)) {
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

    _heroTags.addAll(_sortedMembers.map((m) => m.id));
  }

  Widget _buildParticipantBox(Member member) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Video/Avatar Content
          Positioned.fill(child: _buildVideo(member)),

          // Nombre en esquina superior izquierda
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
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menú de tres puntos
          Align(
            alignment: Alignment.topRight,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(value: 'settings', child: Text('Configuración')),
                    const PopupMenuItem(value: 'info', child: Text('Información')),
                  ],
              onSelected: (value) => _handleMenuSelection(value, member),
            ),
          ),

          // Indicador de calidad de señal
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

  Widget _buildVideo(Member member) {
    return widget.videoBuilder?.call(context, member, widget.renders[member.id]) ??
        RendererBox(renderer: widget.renders[member.id]!, member: member, mirror: true);
  }

  Widget _buildSingleLayout() {
    final member = _sortedMembers.first;
    return AnimatedSwitcher(
      duration: widget.layoutTransitionDuration,
      child: Container(
        key: ValueKey(member.id),
        child: AspectRatio(aspectRatio: 1, child: _buildParticipantBox(member)),
      ),
    );
  }

  Widget _buildDualLayout() {
    return Column(
      children:
          _sortedMembers.take(2).map((member) {
            return Expanded(
              child: AnimatedSwitcher(
                duration: widget.layoutTransitionDuration,
                child: Container(
                  key: ValueKey(member.id),
                  child: AspectRatio(aspectRatio: 1, child: _buildParticipantBox(member)),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildGridLayout() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: _sortedMembers.length <= 4 ? 0.5 : 1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _sortedMembers.length,
      itemBuilder: (context, index) {
        final member = _sortedMembers[index];
        return AnimatedSwitcher(
          duration: widget.layoutTransitionDuration,
          child: _buildParticipantBox(member),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.layoutTransitionDuration,
      switchInCurve: widget.layoutTransitionCurve,
      child: _buildLayout(),
    );
  }

  Widget _buildLayout() {
    if (_sortedMembers.isEmpty) return const SizedBox.shrink();
    if (_sortedMembers.length == 1) return _buildSingleLayout();
    if (_sortedMembers.length == 2) return _buildDualLayout();

    return _buildGridLayout();
  }

  void _handleMenuSelection(String value, Member member) {
    // Implementar lógica del menú
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

class RendererBox extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final Member member;
  final bool mirror;

  bool get available => member.cameraEnabled;

  String get photoUrl => member.photoUrlOrId;

  const RendererBox({
    super.key,
    required this.member,
    required this.renderer,
    required this.mirror,
  });

  @override
  Widget build(BuildContext context) {
    return available
        ? Transform.scale(scale: mirror ? -1.0 : 1.0, child: RTCVideoView(renderer))
        : _buildAvatar(member);
  }

  Widget _buildAvatar(Member member) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        image: DecorationImage(
          image: NetworkImage(member.photoUrlOrId),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Text(
          member.displayNameOrId[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
