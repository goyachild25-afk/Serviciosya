import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/level_badge.dart';
import '../models/service_provider_model.dart';

class ProviderCard extends StatefulWidget {
  final ServiceProviderModel provider;
  final VoidCallback onTap;
  final bool compact;

  const ProviderCard({
    super.key,
    required this.provider,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  bool _pressed = false;

  void _onTapDown(_) => setState(() => _pressed = true);
  void _onTapUp(_) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeInOut,
        child: widget.compact
            ? _buildListTile(context)
            : _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: 186,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _pressed ? 0.03 : 0.06),
            blurRadius: _pressed ? 8 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Imagen / Avatar ───────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(19)),
            child: Stack(
              children: [
                _buildAvatar(height: 118),
                // Badge verificado
                if (widget.provider.isVerified)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.4),
                              blurRadius: 6),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          Text('Verificado',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                // Badge rating
                if (widget.provider.rating > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 10, color: AppColors.star),
                          const SizedBox(width: 3),
                          Text(
                            widget.provider.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                // No disponible overlay
                if (!widget.provider.isAvailable)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No disponible',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Info ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.provider.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 11, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        widget.provider.locationLabel,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    LevelBadge(widget.provider.level),
                    const Spacer(),
                    Text(
                      _shortPriceLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: _pressed
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildAvatar(width: 70, height: 70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.provider.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.provider.isVerified)
                      const Icon(Icons.verified,
                          color: AppColors.success, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        widget.provider.locationLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RatingStars(
                  rating: widget.provider.rating,
                  size: 14,
                  reviewCount: widget.provider.reviewCount,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    LevelBadge(widget.provider.level),
                    const SizedBox(width: 6),
                    Text(
                      '· ${widget.provider.completedJobs} trabajos',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        _shortPriceLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }

  Widget _buildAvatar({double? width, double? height}) {
    if (widget.provider.avatarUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.provider.avatarUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 350),
        fadeInCurve: Curves.easeIn,
        placeholder: (_, __) =>
            _avatarPlaceholder(width: width, height: height),
        errorWidget: (_, __, ___) =>
            _avatarPlaceholder(width: width, height: height),
      );
    }
    return _avatarPlaceholder(width: width, height: height);
  }

  Widget _avatarPlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.primaryLighter,
      alignment: Alignment.center,
      child: Text(
        widget.provider.fullName.isNotEmpty
            ? widget.provider.fullName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  String get _shortPriceLabel {
    if (widget.provider.services.isEmpty) return 'A cotizar';
    final fixed = widget.provider.services
        .where((s) =>
            s.pricingType == PricingType.fixed && s.fixedPrice != null)
        .toList();
    if (fixed.isNotEmpty) {
      final min = fixed
          .map((s) => s.fixedPrice!)
          .reduce((a, b) => a < b ? a : b);
      return 'Desde \$${min.toStringAsFixed(0)}';
    }
    return 'A cotizar';
  }
}
