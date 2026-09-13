import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../state/planner_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';

/// Feature four: study progress analytics.
///
/// Three visualisations are derived from the same domain state: a weekly focus
/// bar chart, an overall completion meter and a per-subject donut. Every series
/// is computed from recorded sessions and task statuses, so the charts remain
/// correct as the student works.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const List<Color> _palette = <Color>[
    Color(0xFF4F46E5),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PlannerController planner = context.watch<PlannerController>();
    final List<({DateTime day, int minutes})> week = planner.weeklyFocus;
    final int peak = week.fold<int>(
      0,
      (int max, ({DateTime day, int minutes}) e) =>
          e.minutes > max ? e.minutes : max,
    );
    final List<({String subject, int total, int completed})> breakdown =
        planner.subjectBreakdown;

    if (planner.totalTasks == 0 && planner.focusMinutesThisWeek == 0) {
      return const SafeArea(
        child: EmptyState(
          icon: Icons.insights_rounded,
          title: 'No progress to show yet',
          message:
              'Add a task or run a focus session and your statistics will '
              'appear here.',
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: <Widget>[
          Text(
            'Study progress',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Measured from completed tasks and recorded focus time.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SectionHeader(title: 'Summary'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: <Widget>[
              StatTile(
                label: 'Tasks completed',
                value: '${planner.completedTasks}/${planner.totalTasks}',
                icon: Icons.task_alt_rounded,
                colour: const Color(0xFF10B981),
              ),
              StatTile(
                label: 'Focus this week',
                value: Formatters.minutes(planner.focusMinutesThisWeek),
                icon: Icons.timer_rounded,
                colour: const Color(0xFF0EA5E9),
              ),
              StatTile(
                label: 'Daily average',
                value: Formatters.minutes(
                  (planner.focusMinutesThisWeek / 7).round(),
                ),
                icon: Icons.calendar_today_rounded,
                colour: const Color(0xFF8B5CF6),
              ),
              StatTile(
                label: 'Current streak',
                value: '${planner.studyStreak} d',
                icon: Icons.local_fire_department_rounded,
                colour: const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SectionHeader(
            title: 'Focus minutes',
            subtitle: 'Last seven days',
          ),
          AppCard(
            padding: const EdgeInsets.fromLTRB(10, 22, 18, 10),
            child: SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (peak == 0 ? 60 : peak * 1.25),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (double value) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value == 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${value.round()}',
                            style: theme.textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int index = value.toInt();
                          if (index < 0 || index >= week.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              Formatters.weekdayShort(week[index].day),
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: <BarChartGroupData>[
                    for (int i = 0; i < week.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: <BarChartRodData>[
                          BarChartRodData(
                            toY: week[i].minutes.toDouble(),
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            color: i == week.length - 1
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withOpacity(0.45),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SectionHeader(title: 'Overall completion'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      '${(planner.completionRate * 100).round()}%',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '${planner.completedTasks} of ${planner.totalTasks} '
                        'tasks completed, ${planner.overdueTasks} overdue.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Semantics(
                  label: 'Overall completion '
                      '${(planner.completionRate * 100).round()} per cent',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: planner.completionRate,
                    ),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext context, double value, Widget? _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 12,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (breakdown.isNotEmpty) ...<Widget>[
            const SectionHeader(
              title: 'By subject',
              subtitle: 'Share of your total workload',
            ),
            AppCard(
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 34,
                        sections: <PieChartSectionData>[
                          for (int i = 0; i < breakdown.length; i++)
                            PieChartSectionData(
                              value: breakdown[i].total.toDouble(),
                              color: _palette[i % _palette.length],
                              radius: 28,
                              title: '',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (int i = 0; i < breakdown.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _palette[i % _palette.length],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    breakdown[i].subject,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                Text(
                                  '${breakdown[i].completed}/'
                                  '${breakdown[i].total}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
