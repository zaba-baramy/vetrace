import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminNotificationTab extends StatefulWidget {
  const AdminNotificationTab({super.key});

  @override
  State<AdminNotificationTab> createState() => _AdminNotificationTabState();
}

class _AdminNotificationTabState extends State<AdminNotificationTab> {
  final TextEditingController _msgController = TextEditingController();
  bool _isSending = false;
  String _selectedTarget = 'ALL';
  String _adminName = "Head Admin";

  @override
  void initState() {
    super.initState();
    _fetchAdminName();
    _autoCleanupOldLogs();
  }

  void _fetchAdminName() async {
    try {
      String? email = FirebaseAuth.instance.currentUser?.email;
      if (email != null) {
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(email.toLowerCase())
            .get();
        if (!mounted) return;
        if (adminDoc.exists) {
          setState(() => _adminName = adminDoc['name'] ?? 'Head Admin');
        }
      }
    } catch (e) {
      debugPrint("Error fetching admin name: $e");
    }
  }

  void _autoCleanupOldLogs() async {
    DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    var oldLogs = await FirebaseFirestore.instance
        .collection('notifications')
        .where('targetBus', isEqualTo: 'ADMIN')
        .where('timestamp', isLessThan: oneWeekAgo)
        .get();

    if (oldLogs.docs.isNotEmpty) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in oldLogs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _clearGlobalOldNotifications() async {
    final messenger = ScaffoldMessenger.of(context);
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deep Clean Database?"),
        content: const Text("Permanently delete ALL records older than 30 days?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("PURGE"),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('timestamp', isLessThan: cutoff)
          .get();

      if (snapshot.docs.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text("No old data found.")));
        return;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      messenger.showSnackBar(
          SnackBar(content: Text("Deleted ${snapshot.docs.length} stale records."))
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _clearAdminLogs() async {
    final messenger = ScaffoldMessenger.of(context);
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Activity Logs?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("CLEAR ALL"),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    var snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('targetBus', isEqualTo: 'ADMIN')
        .get();

    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    messenger.showSnackBar(const SnackBar(content: Text("Logs cleared.")));
  }

  void _sendNotification() async {
    if (_msgController.text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'message': _msgController.text.trim(),
        'targetBus': _selectedTarget,
        'timestamp': FieldValue.serverTimestamp(),
        'adminName': _adminName,
      });
      _msgController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        messenger.showSnackBar(const SnackBar(content: Text("Notification sent!")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final aDate = DateTime(date.year, date.month, date.day);

    if (aDate == today) return "Today";
    if (aDate == yesterday) return "Yesterday";
    return DateFormat('MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.blue[900],
            child: const TabBar(
              indicatorColor: Colors.amber,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: Icon(Icons.send), text: "Broadcast"),
                Tab(icon: Icon(Icons.list_alt), text: "Activity Log"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBroadcastTab(),
                _buildActivityLogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: BROADCAST INTERFACE ---
  Widget _buildBroadcastTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("New Announcement",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _selectedTarget,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: "Target Recipients"),
          items: ['ALL', 'BUS-A', 'BUS-B', 'BUS-C']
              .map((id) => DropdownMenuItem(
            value: id,
            child: Text(id == 'ALL' ? "All Parents" : "Parents of $id"),
          ))
              .toList(),
          onChanged: (val) => setState(() => _selectedTarget = val!),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _msgController,
          maxLines: 4,
          decoration: const InputDecoration(
              hintText: "Enter the announcement message here...",
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        _isSending
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
          onPressed: _sendNotification,
          icon: const Icon(Icons.campaign, color: Colors.black),
          label: const Text("SEND NOTIFICATION",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 40),
        const Divider(),
        const SizedBox(height: 20),
        _buildMaintenanceSection(),
      ],
    );
  }

  // --- TAB 2: ACTIVITY LOG INTERFACE ---
  Widget _buildActivityLogTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("System Events",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              TextButton.icon(
                onPressed: _clearAdminLogs,
                icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
                label: const Text("Clear Logs",
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('targetBus', isEqualTo: 'ADMIN')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No recent activity logs."));

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  DateTime date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                  String currentHeader = _getFormattedDate(date);
                  bool showHeader = false;
                  if (index == 0) {
                    showHeader = true;
                  } else {
                    var prevData = snapshot.data!.docs[index - 1].data() as Map<String, dynamic>;
                    var prevDate = (prevData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    if (_getFormattedDate(prevDate) != currentHeader) {
                      showHeader = true;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.grey[200],
                          child: Text(currentHeader,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.info, size: 16, color: Colors.white),
                        ),
                        title: Text(data['message'] ?? ""),
                        subtitle: Text(DateFormat('hh:mm a').format(date)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DATABASE MANAGEMENT",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _clearGlobalOldNotifications,
          icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 20),
          label: const Text("PURGE DATA OLDER THAN 30 DAYS",
              style: TextStyle(color: Colors.red, fontSize: 12)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 45),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Remove both parent announcements and system logs older than a month.",
          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}