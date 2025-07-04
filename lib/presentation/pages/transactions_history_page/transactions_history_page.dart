import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/domain/models/transaction.dart';
import '/presentation/providers.dart';
import '/presentation/shared/default_list_tile.dart';
import '/presentation/theme/app_theme.dart';
import '/presentation/shared/default_app_bar.dart';
import '/presentation/shared/default_header_list_tile.dart';

part 'transactions_history_widgets.dart';

class TransactionsHistoryPage extends ConsumerWidget {
  const TransactionsHistoryPage({super.key, required this.isIncome, required this.onShowAnalysis});

  /// Indicates whether [TransactionsHistoryPage] is about expenses or incomes.
  final bool isIncome;

  final VoidCallback onShowAnalysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = ref.watch(historyStartProvider(isIncome));
    final end = ref.watch(historyEndProvider(isIncome));
    final total = ref.watch(totalAmountProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final sortBy = ref.watch(sortByProvider);

    return Scaffold(
      appBar: DefaultAppBar(
        title: isIncome ? 'История доходов' : 'История расходов',
        actions: [
          IconButton(
            onPressed: onShowAnalysis,
            padding: EdgeInsets.all(12),
            icon: Icon(Icons.pending_actions, size: 24),
          ),
        ],
      ),
      body: Column(
        children: [
          _DateTile(
            label: 'Начало',
            date: start,
            onTap: () => _pickStart(context, ref, start),
          ),
          const Divider(height: 1),
          _DateTile(
            label: 'Конец',
            date: end,
            onTap: () => _pickEnd(context, ref, end),
          ),
          const Divider(height: 1),
          _SortTile(
            sortBy: sortBy,
            onChange: (s) => ref.read(sortByProvider.notifier).state = s,
          ),
          const Divider(height: 1),
          DefaultHeaderListTile(
            leading: Text('Сумма'),
            trailing: Text('${total.toString()} ₽'),
          ),
          Expanded(
            child: transactionsAsync.when(
              data: (_) => _HistoryList(ref.watch(sortedTransactionsProvider)),
              loading: () => const _HistoryLoading(),
              error: (err, _) => Center(child: Text('Error occured: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStart(
    BuildContext context,
    WidgetRef ref,
    DateTime initial,
  ) async {
    final picked = await _showPicker(context, initial);
    if (picked != null) {
      updateStartDate(ref, picked);
    }
  }

  Future<void> _pickEnd(
    BuildContext context,
    WidgetRef ref,
    DateTime initial,
  ) async {
    final picked = await _showPicker(context, initial);
    if (picked != null) {
      updateEndDate(ref, picked);
    }
  }

  Future<DateTime?> _showPicker(BuildContext context, DateTime initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.colors.accent,
              onPrimary: context.colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: context.colors.accent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
