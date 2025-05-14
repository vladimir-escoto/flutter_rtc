part of "../call_container_screen.dart";

/// Widget that represents a call control option.
class CallControlOption extends StatelessWidget {
  /// Creates a new instance of [CallControlOption].
  const CallControlOption({
    super.key,
    required this.icon,
    this.isEnable = true,
    this.disableIcon,
    this.iconColor = Colors.black,
    this.disabledIconColor = Colors.grey,
    this.elevation,
    this.backgroundColor,
    this.disabledBackgroundColor = Colors.white,
    this.shape = const CircleBorder(),
    this.padding = const EdgeInsets.all(22),
    this.iconSize,
    this.onPressed,
  });

  final double? iconSize;

  final bool isEnable;

  /// The icon of the call control option.
  final Widget icon;

  /// The icon of the call control option.
  final Widget? disableIcon;

  /// The color of the icon of the call control option.
  final Color? iconColor;

  /// The color of the icon of the call control option when it is disabled.
  final Color? disabledIconColor;

  /// The elevation of the call control option.
  final double? elevation;

  /// The background color of the call control option.
  final Color? backgroundColor;

  /// The background color of the call control option when it is disabled.
  final Color disabledBackgroundColor;

  /// The shape of the call control option.
  final OutlinedBorder? shape;

  /// The padding applied to the call control option.
  final EdgeInsetsGeometry? padding;

  /// The callback to invoke when the user taps on the call control option.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    Color? iconColor;
    if (onPressed != null) {
      iconColor = this.iconColor;
    } else {
      iconColor = disabledIconColor;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: elevation,
        backgroundColor: isEnable ? backgroundColor : disabledBackgroundColor,
        shape: shape,
        padding: padding,
        visualDensity: VisualDensity.comfortable,
        disabledBackgroundColor: disabledBackgroundColor,
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: iconColor, size: iconSize),
        child: !isEnable && disableIcon != null ? disableIcon! : icon,
      ),
    );
  }
}
