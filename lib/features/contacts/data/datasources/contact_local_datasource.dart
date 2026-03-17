import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:dialer_app_poc/features/contacts/data/models/contact_model.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

abstract class ContactLocalDataSource {
  Future<List<ContactModel>> getContacts();
}

class ContactLocalDataSourceImpl implements ContactLocalDataSource {
  @override
  Future<List<ContactModel>> getContacts() async {
    print('[DEBUG] ContactLocalDataSource: Checking contacts permission status...');
    
    // Check current status
    var status = await ph.Permission.contacts.status;
    print('[DEBUG] ContactLocalDataSource: Current permission status: $status');

    if (status.isDenied) {
      print('[DEBUG] ContactLocalDataSource: Permission denied, requesting...');
      status = await ph.Permission.contacts.request();
      print('[DEBUG] ContactLocalDataSource: Request result: $status');
    }

    if (status.isPermanentlyDenied) {
      print('[DEBUG] ContactLocalDataSource: Permission permanently denied. Redirecting to settings?');
      // We can't easily open settings automatically here without more context,
      // but we should throw a specific message.
      throw Exception('Permission permanently denied. Please enable in settings.');
    }

    if (status.isGranted) {
      print('[DEBUG] ContactLocalDataSource: Permission granted. Fetching contacts...');
      // Even if granted by permission_handler, flutter_contacts might need its own initialization if any
      // but usually it works directly if permission is granted.
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      print('[DEBUG] ContactLocalDataSource: Successfully fetched ${contacts.length} contacts');
      return contacts.map((c) => ContactModel.fromFlutterContact(c)).toList();
    } else {
      print('[DEBUG] ContactLocalDataSource: Permission NOT granted (Status: $status)');
      throw Exception('Contacts permission is required to use this app.');
    }
  }
}
