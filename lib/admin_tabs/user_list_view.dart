import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListView extends StatefulWidget {
  final Function(String) onDelete;

  const UserListView({super.key, required this.onDelete});

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search name or email...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              }) : null,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? "").toString().toLowerCase();
                final email = (data['email'] ?? doc.id).toString().toLowerCase();
                return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) return const Center(child: Text("No users found."));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var doc = docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  // NEW: Helper variables for better readability
                  String role = (data['role'] ?? 'parent').toString().toLowerCase();
                  String busId = data['busId'] ?? 'N/A';
                  String address = data['address'] ?? 'No address set';
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: role == 'driver' ? Colors.blue[100] : Colors.green[100],
                        child: Icon(role == 'driver' ? Icons.directions_bus : Icons.home_work), // Changed icon for parent
                      ),
                      title: Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),

                      // IMPROVED SUBTITLE: Shows Address for Parents
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Role: ${role.toUpperCase()} | Bus: $busId"),
                          if (role == 'parent')
                            Text(
                              "Stop: $address",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                        ],
                      ),
                      isThreeLine: role == 'parent', // Makes card taller if there is an address
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => widget.onDelete(doc.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}