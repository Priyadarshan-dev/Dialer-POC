import 'package:flutter/services.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';

class CallDirectoryService {
  static const MethodChannel _channel = MethodChannel('com.liquid.dialer/call_directory');

  /// Synchronizes call notes with the iOS Call Directory Extension.
  /// 
  /// This method takes a list of [CallHistoryEntity], extracts the phone numbers
  /// and notes, and sends them to the native iOS side via Method Channel.
  Future<void> syncData(List<CallHistoryEntity> calls) async {
    try {
      // 1. Create a map of PhoneNumber -> Note
      // Only include numbers that have notes.
      final Map<String, String> data = {};
      
      for (var call in calls) {
        if (call.notes != null && call.notes!.isNotEmpty) {
          // Clean the phone number (remove non-digits except possibly a leading +)
          final cleanedNumber = _formatPhoneNumber(call.phoneNumber);
          if (cleanedNumber.isNotEmpty) {
            // We prepend the app name to the note for better visibility on the call screen
            data[cleanedNumber] = '${AppConstants.appName}: ${call.notes}';
          }
        }
      }

      if (data.isEmpty) {
        print('[DEBUG] CallDirectoryService: No notes to sync.');
        return;
      }

      // 2. Invoke native method to save data to App Group and reload extension
      print('[DEBUG] CallDirectoryService: Syncing ${data.length} entries to iOS...');
      await _channel.invokeMethod('syncAndReload', {
        'appGroupId': AppConstants.appGroupId,
        'fileName': AppConstants.callDirectoryFileName,
        'data': data,
      });
      
      print('[DEBUG] CallDirectoryService: Sync successful.');
    } on PlatformException catch (e) {
      print('[DEBUG] CallDirectoryService: Failed to sync data: ${e.message}');
    } catch (e) {
      print('[DEBUG] CallDirectoryService: Unexpected error during sync: $e');
    }
  }

  /// Formats the phone number for CallKit.
  /// CallKit expects numbers to be in a consistent format (usually digits only).
  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // If it's a valid number, we return it. 
    // Note: In a real app, you'd want to ensure it has a country code.
    return digits;
  }
}
