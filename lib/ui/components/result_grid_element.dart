// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_size_text/auto_size_text.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

// Project imports:
import 'package:spotify_dart/interfaces/spotify.dart';

/// A grid element for displaying a list of [SimplifiedSResult]s with a
/// [StickyHeader].
class ResultGridElement extends StatelessWidget {
  /// The number of columns in the grid.
  final int crossAxisCount;

  /// The title of the [StickyHeader].
  final String sliderTitle;

  /// The list of [SimplifiedSResult]s to display.
  final List<SimplifiedSResult> results;

  final void Function(String resultId) onClick;

  /// Construct a grid element for displaying a list of [SimplifiedSResult]s
  /// with a [StickyHeader].
  const ResultGridElement({
    super.key,
    this.crossAxisCount = 3,
    required this.results,
    required this.sliderTitle,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    var titleGroup = AutoSizeGroup();
    var artistGroup = AutoSizeGroup();

    return StickyHeader(
      header: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            sliderTitle,
            style: Theme.of(context).textTheme.headlineLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),

      // Content Cards
      content: GridView.count(
        shrinkWrap: true,
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1 / 1.4,
        children: [
          for (var result in results)
            GestureDetector(
              child: Card(
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Center(child: Image.network(result.artUrl, width: double.infinity)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: AutoSizeText(
                                  result.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge!
                                      .copyWith(fontWeight: FontWeight.bold),
                                  group: titleGroup,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: AutoSizeText(
                                  result.artists.join(', '),
                                  style: Theme.of(context).textTheme.titleLarge,
                                  group: artistGroup,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              onTap: () => onClick(result.id),
            ),
        ],
      ),
    );
  }
}
