import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class _FunnelStep {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  const _FunnelStep({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
}

class _AnalyticsData {
  final List<_FunnelStep> funnel;
  final Map<DateTime, int> eventsByDay; // últimos 14 días
  final int totalReferralInvites;
  final int completedReferralActivations;
  final List<_EventCount> topEvents;
  final Duration? avgTimeToAcceptance;
  const _AnalyticsData({
    required this.funnel,
    required this.eventsByDay,
    required this.totalReferralInvites,
    required this.completedReferralActivations,
    required this.topEvents,
    required this.avgTimeToAcceptance,
  });
}

class _EventCount {
  final String name;
  final int count;
  const _EventCount(this.name, this.count);
}

final _analyticsDataProvider =
    FutureProvider.autoDispose<_AnalyticsData>((ref) async {
  final since14 =
      DateTime.now().subtract(const Duration(days: 14)).toIso8601String();

  // Embudo
  final results = await Future.wait<dynamic>([
    // signups (todos los profiles creados en 14d)
    SupabaseService.client
        .from('profiles')
        .select('id')
        .gte('created_at', since14),
    // bookings creados (14d)
    SupabaseService.client
        .from('bookings')
        .select('id')
        .gte('created_at', since14),
    // bookings aceptados alguna vez (14d), con created_at/accepted_at para
    // el tiempo hasta primera aceptación. accepted_at no se pisa en
    // transiciones posteriores (in_progress, completed) a diferencia de
    // updated_at — por eso filtramos por accepted_at, no por status
    // actual, o subestimaríamos el conteo del embudo.
    SupabaseService.client
        .from('bookings')
        .select('created_at, accepted_at')
        .not('accepted_at', 'is', null)
        .gte('created_at', since14),
    // bookings completados (14d)
    SupabaseService.client
        .from('bookings')
        .select('id, agreed_price')
        .eq('status', 'completed')
        .gte('created_at', since14),
    // eventos brutos (14d)
    SupabaseService.client
        .from('analytics_events')
        .select('name, created_at')
        .gte('created_at', since14),
    // Referidos
    SupabaseService.client
        .from('profiles')
        .select('id, referred_by')
        .not('referred_by', 'is', null),
  ]);

  final signups = (results[0] as List<dynamic>).length;
  final bookingsCreated = (results[1] as List<dynamic>).length;
  final acceptedBookings = (results[2] as List<dynamic>).cast<Map<String, dynamic>>();
  final bookingsAccepted = acceptedBookings.length;
  final bookingsCompleted = (results[3] as List<dynamic>).length;
  final events = (results[4] as List<dynamic>).cast<Map<String, dynamic>>();
  final referrals = (results[5] as List<dynamic>).cast<Map<String, dynamic>>();

  // Tiempo hasta primera aceptación: promedio de (accepted_at - created_at)
  // sobre las reservas de la ventana que ya fueron aceptadas. Sin datos
  // todavía si nadie aceptó nada en 14 días (columna nueva desde hoy).
  Duration? avgTimeToAcceptance;
  final gaps = <Duration>[];
  for (final b in acceptedBookings) {
    final created = DateTime.tryParse(b['created_at'] as String? ?? '');
    final accepted = DateTime.tryParse(b['accepted_at'] as String? ?? '');
    if (created == null || accepted == null) continue;
    final gap = accepted.difference(created);
    if (!gap.isNegative) gaps.add(gap);
  }
  if (gaps.isNotEmpty) {
    final totalMs = gaps.fold<int>(0, (sum, g) => sum + g.inMilliseconds);
    avgTimeToAcceptance = Duration(milliseconds: totalMs ~/ gaps.length);
  }

  final funnel = [
    _FunnelStep(
      label: 'Registros',
      count: signups,
      icon: Icons.person_add_rounded,
      color: AppColors.primary,
    ),
    _FunnelStep(
      label: 'Reservas creadas',
      count: bookingsCreated,
      icon: Icons.event_note_rounded,
      color: AppColors.info,
    ),
    _FunnelStep(
      label: 'Aceptadas',
      count: bookingsAccepted,
      icon: Icons.thumb_up_alt_rounded,
      color: AppColors.warning,
    ),
    _FunnelStep(
      label: 'Completadas',
      count: bookingsCompleted,
      icon: Icons.verified_rounded,
      color: AppColors.success,
    ),
  ];

  // Eventos por día
  final byDay = <DateTime, int>{};
  for (int i = 13; i >= 0; i--) {
    final d = DateTime.now().subtract(Duration(days: i));
    byDay[DateTime(d.year, d.month, d.day)] = 0;
  }
  for (final e in events) {
    final ts = DateTime.tryParse(e['created_at'] as String? ?? '');
    if (ts == null) continue;
    final key = DateTime(ts.year, ts.month, ts.day);
    byDay[key] = (byDay[key] ?? 0) + 1;
  }

  // Top eventos
  final eventCounts = <String, int>{};
  for (final e in events) {
    final n = e['name'] as String? ?? '';
    if (n.isEmpty) continue;
    eventCounts[n] = (eventCounts[n] ?? 0) + 1;
  }
  final topEvents = (eventCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .take(5)
      .map((e) => _EventCount(e.key, e.value))
      .toList();

  return _AnalyticsData(
    funnel: funnel,
    eventsByDay: byDay,
    totalReferralInvites: referrals.length,
    completedReferralActivations: referrals.length,
    topEvents: topEvents,
    avgTimeToAcceptance: avgTimeToAcceptance,
  );
});

/// "2h 15min", "45min", o "3d 2h" según la magnitud.
String _formatDuration(Duration d) {
  if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}min';
  return '${d.inMinutes}min';
}

class AdminAnalyticsTab extends ConsumerWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_analyticsDataProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('No pudimos cargar analytics.'),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Últimos 14 días',
                style: TextStyle(fontSize: 14, color: AppColors.textHint)),
            const SizedBox(height: 12),

            // Embudo
            const Text('Embudo de conversión',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _FunnelChart(steps: data.funnel),
            const SizedBox(height: 12),

            // Tiempo hasta primera aceptación
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.avgTimeToAcceptance != null
                              ? _formatDuration(data.avgTimeToAcceptance!)
                              : 'Sin datos aún',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.info),
                        ),
                        const Text('Tiempo promedio hasta primera aceptación',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Eventos por día (mini bar chart)
            const Text('Actividad diaria',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _DailyBars(byDay: data.eventsByDay),
            const SizedBox(height: 24),

            // Referidos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data.totalReferralInvites} referidos activos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Usuarios que se registraron con código de invitación',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Top eventos
            const Text('Eventos más frecuentes',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  if (data.topEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Aún no hay eventos registrados.',
                          style: TextStyle(color: AppColors.textHint)),
                    ),
                  ...data.topEvents.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(e.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                            Text('${e.count}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FunnelChart extends StatelessWidget {
  final List<_FunnelStep> steps;
  const _FunnelChart({required this.steps});

  @override
  Widget build(BuildContext context) {
    final max = steps.map((s) => s.count).fold<int>(0, (a, b) => a > b ? a : b);
    return Column(
      children: steps.map((s) {
        final ratio = max == 0 ? 0.0 : s.count / max;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(s.icon, color: s.color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.label,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('${s.count}',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: s.color)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: s.color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(s.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DailyBars extends StatelessWidget {
  final Map<DateTime, int> byDay;
  const _DailyBars({required this.byDay});

  @override
  Widget build(BuildContext context) {
    final entries = byDay.entries.toList();
    final maxCount =
        entries.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: entries.map((e) {
            final ratio = maxCount == 0 ? 0.0 : e.value / maxCount;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${e.value}',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: 2),
                Container(
                  width: 14,
                  height: 90 * ratio + 4,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(DateFormat('dd/MM').format(e.key),
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textHint)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
