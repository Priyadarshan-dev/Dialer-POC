import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dialer_app_poc/core/usecases/usecase.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/features/call_history/domain/usecases/call_history_usecases.dart';
import 'package:dialer_app_poc/features/call_history/presentation/states/call_history_state.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

class CallHistoryNotifier extends StateNotifier<CallHistoryState> {
  final GetAllCallsUseCase _getAllCallsUseCase;
  final SaveCallUseCase _saveCallUseCase;
  final UpdateCallNotesUseCase _updateCallNotesUseCase;
  final DeleteCallUseCase _deleteCallUseCase;
  final MarkCompletedUseCase _markCompletedUseCase;

  CallHistoryNotifier({
    required GetAllCallsUseCase getAllCallsUseCase,
    required SaveCallUseCase saveCallUseCase,
    required UpdateCallNotesUseCase updateCallNotesUseCase,
    required DeleteCallUseCase deleteCallUseCase,
    required MarkCompletedUseCase markCompletedUseCase,
  })  : _getAllCallsUseCase = getAllCallsUseCase,
        _saveCallUseCase = saveCallUseCase,
        _updateCallNotesUseCase = updateCallNotesUseCase,
        _deleteCallUseCase = deleteCallUseCase,
        _markCompletedUseCase = markCompletedUseCase,
        super(CallHistoryState());

  Future<void> loadCalls() async {
    print('[DEBUG] CallHistoryNotifier: Starting loadCalls...');
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAllCallsUseCase(NoParams());
    result.fold(
      (failure) {
        print('[DEBUG] CallHistoryNotifier: Load failed with failure: $failure');
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (calls) {
        final sortedCalls = List<CallHistoryEntity>.from(calls)
          ..sort((a, b) => b.callTime.compareTo(a.callTime));
        final pending = sortedCalls.where((c) => c.status == AppConstants.statusPending).toList();
        print('[DEBUG] CallHistoryNotifier: Load successful. Total: ${calls.length}, Pending: ${pending.length}');
        state = state.copyWith(
          isLoading: false,
          calls: sortedCalls,
          pendingCalls: pending,
        );
        _updateBadgeCount(pending.length);
      },
    );
  }

  Future<void> saveCall(CallHistoryEntity call) async {
    print('[DEBUG] CallHistoryNotifier: Saving call for ${call.contactName} (${call.phoneNumber})...');
    final result = await _saveCallUseCase(call);
    result.fold(
      (failure) {
        print('[DEBUG] CallHistoryNotifier: Save failed: $failure');
        state = state.copyWith(error: failure.message);
      },
      (_) async {
        print('[DEBUG] CallHistoryNotifier: Save successful. Refreshing calls...');
        await loadCalls();
      },
    );
  }

  Future<void> updateNotes(String id, String notes) async {
    print('[DEBUG] CallHistoryNotifier: Updating notes for call $id...');
    final result = await _updateCallNotesUseCase(UpdateNotesParams(id: id, notes: notes));
    result.fold(
      (failure) {
        print('[DEBUG] CallHistoryNotifier: Update notes failed: $failure');
        state = state.copyWith(error: failure.message);
      },
      (_) {
        print('[DEBUG] CallHistoryNotifier: Update notes successful. Refreshing calls...');
        loadCalls();
      },
    );
  }

  Future<void> deleteCall(String id) async {
    print('[DEBUG] CallHistoryNotifier: Deleting call $id...');
    final result = await _deleteCallUseCase(id);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => loadCalls(),
    );
  }

  Future<void> markCompleted(String id) async {
    print('[DEBUG] CallHistoryNotifier: Marking call $id as COMPLETED...');
    final result = await _markCompletedUseCase(id);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => loadCalls(),
    );
  }

  void _updateBadgeCount(int count) {
    if (count > 0) {
      FlutterAppBadger.updateBadgeCount(count);
    } else {
      FlutterAppBadger.removeBadge();
    }
  }
}
