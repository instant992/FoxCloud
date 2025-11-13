import 'package:flowvy/enum/enum.dart';
import 'package:flutter/material.dart';
import 'package:emoji_regex/emoji_regex.dart';

import '../state.dart';

class TooltipText extends StatelessWidget {
  final Text text;

  const TooltipText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, container) {
        final maxWidth = container.maxWidth;
        final size = globalState.measure.computeTextSize(
          text,
        );
        if (maxWidth < size.width) {
          return Tooltip(
            preferBelow: false,
            message: text.data,
            child: text,
          );
        }
        return text;
      },
    );
  }
}

// Cache for parsed emoji text spans to avoid expensive regex operations
final Map<String, List<TextSpan>> _emojiTextCache = {};

class EmojiText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const EmojiText(
    this.text, {
    super.key,
    this.maxLines,
    this.overflow,
    this.style,
  });

  List<TextSpan> _buildTextSpans(String emojis) {
    // Create cache key (text only, style is applied later)
    final cacheKey = text;

    // Check cache first
    if (_emojiTextCache.containsKey(cacheKey)) {
      // Return cached spans with current style applied
      return _emojiTextCache[cacheKey]!.map((span) {
        if (span.text != null && span.style?.fontFamily == FontFamily.twEmoji.value) {
          // Emoji span
          return TextSpan(
            text: span.text,
            style: style?.copyWith(
              fontFamily: FontFamily.twEmoji.value,
            ),
          );
        } else {
          // Regular text span
          return TextSpan(text: span.text, style: style);
        }
      }).toList();
    }

    // Parse and create spans
    final List<TextSpan> spans = [];
    final matches = emojiRegex().allMatches(text);

    int lastMatchEnd = 0;
    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
              text: text.substring(lastMatchEnd, match.start), style: null),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            fontFamily: FontFamily.twEmoji.value,
          ),
        ),
      );
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: null,
        ),
      );
    }

    // Cache the parsed structure (limit cache size)
    if (_emojiTextCache.length < 500) {
      _emojiTextCache[cacheKey] = spans;
    }

    // Return with style applied
    return spans.map((span) {
      if (span.text != null && span.style?.fontFamily == FontFamily.twEmoji.value) {
        return TextSpan(
          text: span.text,
          style: style?.copyWith(
            fontFamily: FontFamily.twEmoji.value,
          ),
        );
      } else {
        return TextSpan(text: span.text, style: style);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textScaler: MediaQuery.of(context).textScaler,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(
        children: _buildTextSpans(text),
      ),
    );
  }
}
