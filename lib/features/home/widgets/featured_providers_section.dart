import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers_list/providers/providers_list_provider.dart';
import '../../providers_list/widgets/provider_card.dart';

class FeaturedProvidersSection extends ConsumerWidget {
  const FeaturedProvidersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(providersListProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mejor calificados ⭐',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/providers'),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        providersAsync.when(
          loading: () => SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => _ProviderShimmer(),
            ),
          ),
          error: (e, _) => const Center(
            child: Text('No se pudieron cargar los prestadores'),
          ),
          data: (providers) {
            if (providers.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Sé de los primeros prestadores en YALO — ¡regístrate ya!',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final featured = providers.take(8).toList();
            return SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _FadeInCard(
                  delay: Duration(milliseconds: i * 60),
                  child: ProviderCard(
                    provider: featured[i],
                    onTap: () => context.push('/provider/${featured[i].id}'),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProviderShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// Wrapper que hace aparecer su hijo con fade + slide escalonado
class _FadeInCard extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeInCard({required this.child, required this.delay});

  @override
  State<_FadeInCard> createState() => _FadeInCardState();
}

class _FadeInCardState extends State<_FadeInCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _fade, child: widget.child),
    );
  }
}
