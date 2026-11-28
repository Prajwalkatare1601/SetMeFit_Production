import 'dart:io';
import 'package:supabase/supabase.dart';

const supabaseUrl = 'https://zggvexvrazqdxfxtbfbc.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpnZ3ZleHZyYXpxZHhmeHRiZmJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTU1MTI0NzIsImV4cCI6MjExMTA4ODQ3Mn0.Z8bUbdGIny8Io_Ras6NHMZvGFhhaLkSo5zrk1eG3dXc';

Future<void> main(List<String> args) async {
  print('================================================================');
  print('          SETMEFIT DATABASE CONNECTION & STATUS TEST            ');
  print('================================================================');
  print('Target Supabase URL : $supabaseUrl');
  print('Anon Key Configured : Yes (${supabaseAnonKey.substring(0, 15)}...)');
  print('Timestamp           : ${DateTime.now().toIso8601String()}\n');

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  // ---------------------------------------------------------
  // 1. Connection & Latency Test
  // ---------------------------------------------------------
  stdout.write('[1/4] Testing Server Reachability & Latency... ');
  final stopwatch = Stopwatch()..start();
  bool isReachable = false;
  try {
    final clientHttp = HttpClient();
    final request = await clientHttp.getUrl(Uri.parse('$supabaseUrl/auth/v1/health'));
    request.headers.set('apikey', supabaseAnonKey);
    final response = await request.close();
    stopwatch.stop();
    if (response.statusCode == 200) {
      isReachable = true;
      print('CONNECTED (HTTP 200, ${stopwatch.elapsedMilliseconds} ms)');
    } else {
      print('REACHABLE with status HTTP ${response.statusCode} (${stopwatch.elapsedMilliseconds} ms)');
    }
  } catch (e) {
    stopwatch.stop();
    print('UNREACHABLE ($e)');
    return;
  }

  // Optional: Check if login credentials passed via args
  // Usage: dart run bin/test_db.dart user@example.com mypassword
  if (args.length >= 2) {
    final email = args[0];
    final password = args[1];
    stdout.write('[2/4] Authenticating as $email... ');
    try {
      final authRes = await client.auth.signInWithPassword(email: email, password: password);
      print('SUCCESS (User ID: ${authRes.user?.id})');
    } catch (e) {
      print('AUTH FAILED: $e');
    }
  } else {
    print('[2/4] Testing as Role: [anon] (Unauthenticated API access)');
  }

  // ---------------------------------------------------------
  // 3. Data Read Check
  // ---------------------------------------------------------
  print('\n[3/4] Testing DATA READ from Database:');
  final testTables = [
    {'schema': 'setmefit', 'table': 'flashfit_gyms'},
    {'schema': 'setmefit', 'table': 'user_meals'},
    {'schema': 'setmefit', 'table': 'user_targets'},
    {'schema': 'setmefit', 'table': 'flashfit_slots'},
    {'schema': 'setmefit', 'table': 'flashfit_bookings'},
    {'schema': 'public', 'table': 'flashfit_gyms'},
  ];

  bool readSuccess = false;
  bool schemaPermissionDenied = false;

  for (final target in testTables) {
    final s = target['schema']!;
    final t = target['table']!;
    stdout.write('  - Querying [$s].$t ... ');

    try {
      final query = (s == 'public')
          ? client.from(t).select().limit(1)
          : client.schema(s).from(t).select().limit(1);

      final result = await query;
      readSuccess = true;
      final count = (result as List).length;
      print('PASS (Fetched $count rows)');
    } catch (e) {
      final err = e.toString();
      if (err.contains('42501') || err.contains('permission denied')) {
        schemaPermissionDenied = true;
        print('FAILED -> PostgreSQL 42501: Permission Denied for schema "$s"');
      } else if (err.contains('PGRST205') || err.contains('Could not find')) {
        print('NOT FOUND -> Table does not exist in schema "$s"');
      } else {
        print('FAILED -> $err');
      }
    }
  }

  // ---------------------------------------------------------
  // 4. Data Write Check (Insert -> Verify -> Delete)
  // ---------------------------------------------------------
  print('\n[4/4] Testing DATA WRITE (Insert -> Read back -> Cleanup):');
  final testGymId = '00000000-0000-0000-0000-000000000099';
  bool writeSuccess = false;
  bool verifySuccess = false;
  bool deleteSuccess = false;

  stdout.write('  - Step A: Inserting test record into [setmefit].flashfit_gyms ... ');
  try {
    await client.schema('setmefit').from('flashfit_gyms').insert({
      'id': testGymId,
      'name': 'SetMeFit Connectivity Probe',
      'address': 'Test Lab',
      'city': 'Diagnostic City',
      'locality': 'Network Locality',
    });
    writeSuccess = true;
    print('PASS (Row written)');
  } catch (e) {
    final err = e.toString();
    if (err.contains('42501') || err.contains('permission denied')) {
      schemaPermissionDenied = true;
      print('FAILED -> PostgreSQL 42501: Permission Denied for schema "setmefit"');
    } else {
      print('FAILED -> $err');
    }
  }

  if (writeSuccess) {
    stdout.write('  - Step B: Verifying record by reading back ... ');
    try {
      final res = await client
          .schema('setmefit')
          .from('flashfit_gyms')
          .select()
          .eq('id', testGymId);
      final list = res as List;
      if (list.isNotEmpty) {
        verifySuccess = true;
        print('PASS (Verified record in DB)');
      } else {
        print('FAILED (Record was inserted but not returned on read)');
      }
    } catch (e) {
      print('FAILED -> $e');
    }

    stdout.write('  - Step C: Cleaning up (Deleting test record) ... ');
    try {
      await client.schema('setmefit').from('flashfit_gyms').delete().eq('id', testGymId);
      deleteSuccess = true;
      print('PASS (Test record cleaned up)');
    } catch (e) {
      print('FAILED -> $e');
    }
  }

  // ---------------------------------------------------------
  // Final Status Summary
  // ---------------------------------------------------------
  print('\n================================================================');
  print('                      FINAL STATUS SUMMARY                      ');
  print('================================================================');
  print('DB Server Reachability : ${isReachable ? 'CONNECTED [OK]' : 'DOWN [FAILED]'}');
  print('Data READ Status       : ${readSuccess ? 'WORKING [OK]' : 'BLOCKED / FAILED'}');
  print('Data WRITE Status      : ${writeSuccess ? 'WORKING [OK]' : 'BLOCKED / FAILED'}');
  print('Write Verification     : ${verifySuccess ? 'VERIFIED [OK]' : (writeSuccess ? 'FAILED' : 'SKIPPED')}');
  print('Data Cleanup (DELETE)  : ${deleteSuccess ? 'CLEANED [OK]' : (writeSuccess ? 'FAILED' : 'SKIPPED')}');
  print('================================================================');

  if (schemaPermissionDenied) {
    print('\n[!] ROOT CAUSE IDENTIFIED:');
    print('    PostgreSQL is actively connected, but permissions have not been');
    print('    granted to the Supabase API roles for the "setmefit" schema.');
    print('\n[>] QUICK FIX (Run this one-time SQL in Supabase Dashboard -> SQL Editor):');
    print('----------------------------------------------------------------');
    print('''
GRANT USAGE ON SCHEMA setmefit TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA setmefit TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA setmefit TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA setmefit TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA setmefit GRANT ALL ON TABLES TO anon, authenticated, service_role;
''');
    print('----------------------------------------------------------------');
  } else if (readSuccess && writeSuccess) {
    print('\n[+] Database is fully healthy! Both Data Read and Write are functional.');
  }
}
