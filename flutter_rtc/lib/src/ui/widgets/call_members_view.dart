import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';
import 'package:flutter_rtc/src/ui/widgets/video_box.dart';
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
    _sortedMembers = [...widget.members]..sort((a, b) {
      final aValue = a.cameraEnabled ? 1 : 0;
      final bValue = b.cameraEnabled ? 1 : 0;
      return bValue.compareTo(aValue);
    });

    _heroTags.addAll(_sortedMembers.map((m) => m.id));
  }

  Widget _buildAvatar(Member member) {
    return widget.avatarBuilder?.call(context, member) ??
        DefaultAvatarBuilder(member: member);
  }

  Widget _buildVideo(Member member) {
    return widget.videoBuilder?.call(context, member, widget.renders[member.id]) ??
        DefaultVideoBuilder(member: member, renderer: widget.renders[member.id]!);
  }

  Widget _buildSingleLayout() {
    final member = _sortedMembers.first;
    return AnimatedSwitcher(
      duration: widget.layoutTransitionDuration,
      switchInCurve: widget.layoutTransitionCurve,
      child: Container(
        key: ValueKey(member.id),
        child: Center(
          child: Hero(
            tag: member.id,
            child: member.cameraEnabled ? _buildVideo(member) : _buildAvatar(member),
          ),
        ),
      ),
    );
  }

  Widget _buildDualLayout() {
    return Row(
      children:
          _sortedMembers.take(2).map((member) {
            return Expanded(
              child: AnimatedSwitcher(
                duration: widget.layoutTransitionDuration,
                child: Container(
                  key: ValueKey(member.id),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Hero(
                      tag: member.id,
                      child:
                          member.cameraEnabled
                              ? _buildVideo(member)
                              : _buildAvatar(member),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildGridLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateGridColumns(
          itemCount: _sortedMembers.length,
          maxWidth: constraints.maxWidth,
        );

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _sortedMembers.length,
          itemBuilder: (context, index) {
            final member = _sortedMembers[index];
            return AnimatedSwitcher(
              duration: widget.layoutTransitionDuration,
              child: Container(
                key: ValueKey(member.id),
                child: Hero(
                  tag: member.id,
                  child:
                      member.cameraEnabled ? _buildVideo(member) : _buildAvatar(member),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _calculateGridColumns({required int itemCount, required double maxWidth}) {
    if (maxWidth > 1200) return 5;
    if (maxWidth > 800) return 4;
    if (maxWidth > 600) return 3;
    return 2;
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

    return switch (_sortedMembers.length) {
      1 => _buildSingleLayout(),
      2 => _buildDualLayout(),
      _ => _buildGridLayout(),
    };
  }
}

// Default builders
class DefaultAvatarBuilder extends StatelessWidget {
  final Member member;

  const DefaultAvatarBuilder({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: NetworkImage(member.photoUrlOrId),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Text(
          member.displayNameOrId[0].toUpperCase(),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class DefaultVideoBuilder extends StatelessWidget {
  final Member member;
  final RTCVideoRenderer renderer;

  const DefaultVideoBuilder({super.key, required this.member, required this.renderer});

  @override
  Widget build(BuildContext context) {
    return VideoBox(
      renderer: renderer,
      photoUrl: member.photoUrlOrId,
      available: member.cameraEnabled,
      mirror: true,
    );
  }
}
