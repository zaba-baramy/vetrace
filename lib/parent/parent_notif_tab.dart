import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ParentNotifTab extends StatefulWidget {
  const ParentNotifTab({super.key});

  @override
  State<ParentNotifTab> createState() => _ParentNotifTabState();
}

class _ParentNotifTabState extends State<ParentNotifTab> {
  String? _busId;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserEmail = user.email!.toLowerCase();
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserEmail!)
          .get();
      if (mounted && doc.exists) {
        setState(() => _busId = doc.get('busId'));
      }
    }
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final aDate = DateTime(date.year, date.month, date.day);

    if (aDate == today) return "Today";
    if (aDate == yesterday) return "Yesterday";
    return DateFormat('EEEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_busId == null) return const Center(child: CircularProgressIndicator());

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
                Tab(icon: Icon(Icons.campaign), text: "Announcements"),
                Tab(icon: Icon(Icons.history), text: "Trip Activity"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildNotificationList(isAnnouncementTab: true),
                _buildNotificationList(isAnnouncementTab: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList({required bool isAnnouncementTab}) {
    DateTime now = DateTime.now();
    DateTime oneWeekAgo = now.subtract(const Duration(days: 7));
    DateTime oneMonthAgo = now.subtract(const Duration(days: 30));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('targetBus', whereIn: [_busId, 'ALL'])
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String msg = (data['message'] ?? "").toString().toLowerCase();
          DateTime date = (data['timestamp'] as Timestamp?)?.toDate() ?? now;

          // NEW: Private Target Logic
          // A notification is shown if it's public (targetUser is null)
          // OR if it's specifically for this user's email.
          String? targetUser = data['targetUser'];
          bool isForMe = targetUser == null || targetUser.toLowerCase() == _currentUserEmail;

          // Categorization logic based on keywords
          bool isRoutine = msg.contains("started") || msg.contains("stopped") ||
              msg.contains("finished") || msg.contains("initiated");

          bool isCorrectTab = isAnnouncementTab ? !isRoutine : isRoutine;

          return isCorrectTab && isForMe && date.isAfter(oneMonthAgo);
        }).toList();

        if (allDocs.isEmpty) return const Center(child: Text("No data available."));

        // GROUP BY DATE
        Map<String, List<DocumentSnapshot>> groupedMessages = {};
        for (var doc in allDocs) {
          DateTime date = (doc['timestamp'] as Timestamp?)?.toDate() ?? now;
          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          if (groupedMessages[dateKey] == null) groupedMessages[dateKey] = [];
          groupedMessages[dateKey]!.add(doc);
        }

        var sortedKeys = groupedMessages.keys.toList();
        var recentKeys = sortedKeys.where((k) => DateTime.parse(k).isAfter(oneWeekAgo)).toList();
        var archiveKeys = sortedKeys.where((k) => DateTime.parse(k).isBefore(oneWeekAgo) ||
            DateTime.parse(k).isAtSameMomentAs(oneWeekAgo)).toList();

        return ListView(
          children: [
            ...recentKeys.map((dateKey) => _buildExpandableDay(
                dateKey, groupedMessages[dateKey]!, isAnnouncementTab, initiallyExpanded: true
            )),

            if (archiveKeys.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Divider(thickness: 2),
              ),
              const Center(
                child: Text("PREVIOUS WEEKS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
              ),
              ...archiveKeys.map((dateKey) => _buildExpandableDay(
                  dateKey, groupedMessages[dateKey]!, isAnnouncementTab, initiallyExpanded: false
              )),
            ]
          ],
        );
      },
    );
  }

  Widget _buildExpandableDay(String dateKey, List<DocumentSnapshot> logs, bool isAnnouncement, {bool initiallyExpanded = false}) {
    DateTime date = DateTime.parse(dateKey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(
          isAnnouncement ? Icons.campaign : Icons.event_note,
          color: isAnnouncement ? Colors.amber[800] : Colors.blue[900],
        ),
        title: Text(
          _getFormattedDate(date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text("${logs.length} ${isAnnouncement ? 'messages' : 'activities'}", style: const TextStyle(fontSize: 11)),
        children: logs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          DateTime time = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

          return ListTile(
            dense: true,
            title: Text(data['message'] ?? "", style: const TextStyle(fontSize: 13)),
            trailing: Text(DateFormat('hh:mm a').format(time), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          );
        }).toList(),
      ),
    );
  }
}