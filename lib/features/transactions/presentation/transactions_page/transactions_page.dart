import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yndx_homework/features/balance/providers.dart';
import 'package:yndx_homework/features/transactions/providers.dart';
import 'package:yndx_homework/shared/providers/error_providers.dart';
import 'package:yndx_homework/shared/providers/repository_providers.dart';
import 'package:yndx_homework/util/log.dart';
import 'package:yndx_homework/features/account/domain/models/account.dart';
import 'package:yndx_homework/features/transactions/domain/models/category.dart';

import '../../domain/models/transaction.dart';
import '../../../../shared/presentation/widgets/default_app_bar.dart';
import '../../../../shared/presentation/widgets/default_header_list_tile.dart';
import '../../../../shared/presentation/widgets/default_list_tile.dart';
import '../../../../core/theme/app_theme.dart';

part 'transactions_loading_widgets.dart';
part 'transactions_widgets.dart';

@Dependencies([Transactions])
class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({
    super.key,
    required this.isIncome,
    required this.onShowHistory,
  });

  /// Indicates whether [TransactionsPage] is about expenses or incomes
  final bool isIncome;

  /// Navigator 2.0 [Router]'s callback to show history.
  final VoidCallback onShowHistory;

  Future<void> showTransactionModal(
    BuildContext context, {
    Transaction? initial,
    required bool isIncomePage,
  }) {
    return showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: 'Transaction Modal',
      context: context,
      pageBuilder:
          (ctx, __, ___) => TransactionModal(
            key: const ValueKey('_TransactionModal'),
            initial: initial,
            isIncome: isIncomePage,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    // Listen for errors - using ACTUAL Riverpod methods
    ref.listen(transactionsProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          Log.error('Transactions error: $error');

          // This is the REAL way to show errors
          ref
              .read(errorHandlerProvider.notifier)
              .showError(
                error.toString(),
                title:
                    isIncome
                        ? 'Ошибка загрузки доходов'
                        : 'Ошибка загрузки расходов',
              );
        },
      );
    });

    return Scaffold(
      appBar: DefaultAppBar(
        title: isIncome ? 'Доходы сегодня' : 'Расходы сегодня',
        actions: [
          IconButton(
            onPressed: onShowHistory,
            icon: Icon(Icons.history),
            iconSize: 24,
            padding: EdgeInsets.all(12),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (data) {
          print(data);
          return _TransactionsList(data);
        },
        loading: () => _LoadingTransactionsList(),
        error: (error, _) {
          Log.error(error.toString());
          return Center(child: Text("Error occured: $error"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add_rounded,
          color: context.colors.white,
          size: 15.56 * 2,
        ),
        onPressed: () => showTransactionModal(context, isIncomePage: isIncome),
      ),
    );
  }
}
