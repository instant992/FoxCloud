import 'dart:io';

import 'package:flowvy/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';

class CommonTargetIcon extends StatefulWidget {
  final String src;
  final double size;

  const CommonTargetIcon({
    super.key,
    required this.src,
    required this.size,
  });

  @override
  State<CommonTargetIcon> createState() => _CommonTargetIconState();
}

class _CommonTargetIconState extends State<CommonTargetIcon> {
  Future<File>? _iconFuture;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(CommonTargetIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload icon only if src changed
    if (oldWidget.src != widget.src) {
      _loadIcon();
    }
  }

  void _loadIcon() {
    // Only create future for network icons
    if (widget.src.isNotEmpty &&
        widget.src.getBase64 == null &&
        (widget.src.startsWith('http://') || widget.src.startsWith('https://'))) {
      _iconFuture = DefaultCacheManager().getSingleFile(widget.src);
    } else {
      _iconFuture = null;
    }
  }

  Widget _defaultIcon() {
    return Icon(
      IconsExt.target,
      size: widget.size,
    );
  }

  Widget _buildIcon() {
    if (widget.src.isEmpty) {
      return _defaultIcon();
    }

    final base64 = widget.src.getBase64;
    if (base64 != null) {
      return Image.memory(
        base64,
        gaplessPlayback: true,
        errorBuilder: (_, error, ___) {
          return _defaultIcon();
        },
      );
    }

    // Use cached future instead of creating new one
    if (_iconFuture == null) {
      return _defaultIcon();
    }

    return FutureBuilder<File>(
      future: _iconFuture,
      builder: (_, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
            );
          }
          return _defaultIcon();
        }
        return widget.src.isSvg
            ? SvgPicture.file(
                data,
                errorBuilder: (_, __, ___) => _defaultIcon(),
              )
            : Image.file(
                data,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _defaultIcon(),
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _buildIcon(),
    );
  }
}
