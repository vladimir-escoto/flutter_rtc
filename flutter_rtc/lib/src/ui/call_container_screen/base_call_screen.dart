/// Module: BaseScreen Wrapper
/// Provides a reusable scaffold with background, SafeArea, optional appBar, padding, and FAB.
/// Use this to wrap any screen content to ensure consistent layout and styling.

part of "../call_container_screen.dart";

class BaseCallScreen extends StatelessWidget {
  /// The main content of the screen.
  final List<Widget> children;

  /// Optional widget to be displayed at the top of the screen.
  final Widget? topBar;

  /// Optional widget to be displayed at the bottom of the screen.
  final Widget? controls;

  /// Background color of the scaffold.
  final Color backgroundColor;

  /// Padding inside the SafeArea around [child].
  final EdgeInsetsGeometry padding;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Optional bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// Whether to use a safe area around the child.
  final bool safeArea;

  const BaseCallScreen({
    super.key,
    required this.children,
    this.topBar,
    this.controls,
    this.backgroundColor = Colors.black,
    this.padding = EdgeInsets.zero,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: safeArea ? SafeArea(child: _buildLayout()) : _buildLayout(),
    );
  }

  Widget _buildLayout() {
    return Stack(
      children: [
        ...children.map((child) => Positioned.fill(child: child)),

        if (topBar != null)
          Positioned(top: 0, left: 0, right: 0, child: topBar!),

        if (controls != null)
          Positioned(bottom: 0, left: 0, right: 0, child: controls!),
      ],
    );
  }
}
