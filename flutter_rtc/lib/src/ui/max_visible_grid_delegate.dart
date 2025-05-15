import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Resolves the number of columns based on the total item count and orientation.
typedef CrossAxisCountResolver = int Function(int itemCount, bool isPortrait);

/// A SliverGridDelegate that limits both columns and rows dynamically based on
/// orientation and item count, letting overflow scroll normally.
class MaxVisibleGridDelegate extends SliverGridDelegate {
  /// Total number of items in the grid.
  final int itemCount;

  /// Function to compute columns in portrait/landscape.
  final CrossAxisCountResolver crossAxisCountResolver;

  /// Maximum visible rows in portrait orientation.
  final int maxRowsPortrait;

  /// Maximum visible rows in landscape orientation.
  final int maxRowsLandscape;

  /// Horizontal spacing between tiles.
  final double crossAxisSpacing;

  /// Vertical spacing between tiles.
  final double mainAxisSpacing;

  /// Optional padding around the grid.
  final EdgeInsetsGeometry padding;

  const MaxVisibleGridDelegate({
    required this.itemCount,
    required this.crossAxisCountResolver,
    this.maxRowsPortrait = 4,
    this.maxRowsLandscape = 2,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    // Determine orientation by comparing cross and main extents
    final bool isPortrait =
        constraints.crossAxisExtent < constraints.viewportMainAxisExtent;

    // Compute columns based on orientation
    final int crossAxisCount = crossAxisCountResolver(
      itemCount,
      isPortrait,
    ).clamp(1, itemCount);

    // Total rows needed for all items
    final int totalRows = (itemCount / crossAxisCount).ceil();

    // Limit rows for height calculation
    final int visibleRows =
        isPortrait
            ? math.min(totalRows, maxRowsPortrait)
            : math.min(totalRows, maxRowsLandscape);

    // Resolve padding values
    final resolved = padding.resolve(TextDirection.ltr);
    final double horizontalPadding = resolved.left + resolved.right;
    final double verticalPadding = resolved.top + resolved.bottom;

    // Calculate usable extents
    final double usableWidth =
        constraints.crossAxisExtent -
        horizontalPadding -
        crossAxisSpacing * (crossAxisCount - 1);
    final double usableHeight =
        constraints.viewportMainAxisExtent -
        verticalPadding -
        mainAxisSpacing * (visibleRows - 1);

    // Tile dimensions
    final double tileWidth = usableWidth / crossAxisCount;
    final double tileHeight = usableHeight / visibleRows;

    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: tileHeight + mainAxisSpacing,
      crossAxisStride: tileWidth + crossAxisSpacing,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(covariant MaxVisibleGridDelegate old) {
    return old.itemCount != itemCount ||
        old.maxRowsPortrait != maxRowsPortrait ||
        old.maxRowsLandscape != maxRowsLandscape ||
        old.crossAxisSpacing != crossAxisSpacing ||
        old.mainAxisSpacing != mainAxisSpacing ||
        old.padding != padding;
  }
}

// USAGE EXAMPLE:
// GridView.builder(
//   padding: const EdgeInsets.all(8),
//   gridDelegate: MaxVisibleGridDelegate(
//     itemCount: members.length,
//     portraitColumnsBuilder: (count) => 2,
//     landscapeColumnsBuilder: (count) {
//       if (count == 1) return 1;
//       if (count == 2) return 2;
//       if (count == 3) return 3;
//       if (count == 4) return 2;
//       if (count <= 6) return 3;
//       return 4;
//     },
//     maxRowsPortrait: 4,
//     maxRowsLandscape: 2,
//     crossAxisSpacing: 8,
//     mainAxisSpacing: 8,
//     padding: const EdgeInsets.symmetric(vertical: 8),
//   ),
//   itemCount: members.length,
//   itemBuilder: (context, index) => _buildCell(members[index]),
// );
