import 'package:flutter/material.dart';
import 'services/dependency_injection.dart';
import 'app_config.dart';

// Simple widget để test Supabase connection
class SupabaseConnectionTest extends StatefulWidget {
  @override
  _SupabaseConnectionTestState createState() => _SupabaseConnectionTestState();
}

class _SupabaseConnectionTestState extends State<SupabaseConnectionTest> {
  String connectionStatus = 'Testing connection...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      // Initialize Supabase
      await setupDependencies();

      setState(() {
        connectionStatus = '✅ Connected to Supabase successfully!\n'
            'URL: ${SupabaseConfig.url}\n'
            'Ready to use database operations.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        connectionStatus = '❌ Connection failed!\n'
            'Error: $e\n'
            'Please check your URL and anon key in app_config.dart';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Supabase Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                CircularProgressIndicator(),
                SizedBox(height: 20),
              ],
              Icon(
                isLoading
                    ? Icons.hourglass_empty
                    : connectionStatus.contains('✅')
                        ? Icons.check_circle
                        : Icons.error,
                size: 64,
                color: isLoading
                    ? Colors.blue
                    : connectionStatus.contains('✅')
                        ? Colors.green
                        : Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                connectionStatus,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              if (!isLoading && !connectionStatus.contains('✅')) ...[
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                    });
                    _testConnection();
                  },
                  child: Text('Retry Connection'),
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Troubleshooting Steps:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('1. Check lib/services/app_config.dart'),
                        Text('2. Ensure URL format: https://xxx.supabase.co'),
                        Text('3. Use anon public key (not service_role key)'),
                        Text(
                            '4. Run supabase_schema.sql in Supabase Dashboard'),
                        Text('5. Check internet connection'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
