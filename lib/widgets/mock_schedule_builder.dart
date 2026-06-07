import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../data/mock_session_store.dart';
import '../models/schedule_item.dart';

class MockScheduleBuilder extends StatelessWidget {
  const MockScheduleBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, List<ScheduleItem> items) builder;

  @override
  Widget build(BuildContext context) {
    if (!ApiConfig.useMockData) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: MockSessionStore.instance,
      builder: (context, _) {
        return builder(context, MockSessionStore.instance.snapshot());
      },
    );
  }
}
