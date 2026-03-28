import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'user_list_view.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  int _viewIndex = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  // Replace with your actual Google Maps API Key
  final googlePlaces = GoogleMapsPlaces(apiKey: "YOUR_GOOGLE_MAPS_KEY_HERE");
  double? _selectedLat;
  double? _selectedLng;

  String _selectedBusId = 'BUS-A';
  String _selectedRole = 'parent';
  bool _isLoading = false;
  final List<String> _busList = ['BUS-A', 'BUS-B', 'BUS-C'];

  // NEW: Precise Route Information based on Farook College start point
  final Map<String, String> _busRouteInfo = {
    'BUS-A': 'to City (via Meenchanda)',
    'BUS-B': 'to Kottappuram (via Ramanattukara)',
    'BUS-C': 'to Karadaparamba (via Azhinjilam)',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _isEmailValid(String email) {
    // This pattern ensures it ends SPECIFICALLY with .com, .net, .org, or .in
    return RegExp(r'^[\w-.]+@([\w-]+\.)+(com|net|org|in)$').hasMatch(email);
  }

  Future<void> _deleteUser(String email) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove User?"),
        content: Text("Delete records for $email? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(email).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User removed from database")));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _createUser() async {
    final messenger = ScaffoldMessenger.of(context);
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (_selectedRole == 'parent' && (_selectedLat == null || _selectedLng == null)) {
      messenger.showSnackBar(const SnackBar(content: Text("Please search and select a specific address")));
      return;
    }

    if (!_isEmailValid(email)) {
      messenger.showSnackBar(const SnackBar(content: Text("Enter a valid email")));
      return;
    }

    if (password.length < 6) {
      messenger.showSnackBar(const SnackBar(content: Text("Password must be at least 6 characters")));
      return;
    }

    setState(() => _isLoading = true);

    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );

    try {
      await FirebaseAuth.instanceFor(app: secondaryApp).createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'role': _selectedRole,
        'busId': _selectedBusId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedRole == 'parent') {
        userData['stopLat'] = _selectedLat;
        userData['stopLng'] = _selectedLng;
        userData['address'] = _addressController.text;
      }

      await FirebaseFirestore.instance.collection('users').doc(email).set(userData);
      await secondaryApp.delete();

      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text("User Created Successfully!")));

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _addressController.clear();
      _selectedLat = null;
      _selectedLng = null;
      setState(() => _viewIndex = 1);

    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text("Add New"), icon: Icon(Icons.person_add)),
            ButtonSegment(value: 1, label: Text("Manage All"), icon: Icon(Icons.group)),
          ],
          selected: {_viewIndex},
          onSelectionChanged: (newSelection) => setState(() => _viewIndex = newSelection.first),
        ),
        const Divider(height: 30),
        Expanded(
          child: _viewIndex == 0
              ? _buildRegistrationForm()
              : UserListView(onDelete: _deleteUser),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text("Register New User", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email Address", border: OutlineInputBorder(), hintText: "name@example.com")),
          const SizedBox(height: 15),
          TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Assign Password", border: OutlineInputBorder())),
          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(labelText: "Select User Role", border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
            items: ['parent', 'driver'].map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
            onChanged: (val) => setState(() => _selectedRole = val!),
          ),
          const SizedBox(height: 15),

          if (_selectedRole == 'parent') ...[
            TypeAheadField<Prediction>(
              direction: VerticalDirection.up,
              decorationBuilder: (context, child) => Material(
                type: MaterialType.card,
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: child,
              ),
              suggestionsCallback: (search) async {
                if (search.length < 3) return [];
                final response = await googlePlaces.autocomplete(search, components: [Component(Component.country, "in")]);
                return response.status == "OK" ? response.predictions : [];
              },
              builder: (context, controller, focusNode) => TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: "Student's Stop Address",
                  hintText: "Search location...",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_searching),
                ),
              ),
              itemBuilder: (context, prediction) => ListTile(
                leading: const Icon(Icons.map),
                title: Text(prediction.description ?? ""),
              ),
              onSelected: (prediction) async {
                _addressController.text = prediction.description!;
                PlacesDetailsResponse detail = await googlePlaces.getDetailsByPlaceId(prediction.placeId!);
                setState(() {
                  _selectedLat = detail.result.geometry!.location.lat;
                  _selectedLng = detail.result.geometry!.location.lng;
                });
              },
            ),
            if (_selectedLat != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("📍 Coordinates: $_selectedLat, $_selectedLng",
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 15),
          ],

          DropdownButtonFormField<String>(
            initialValue: _selectedBusId,
            decoration: const InputDecoration(labelText: "Assign to Bus", border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_bus)),
            items: _busList.map((bus) => DropdownMenuItem(
              value: bus,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bus, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(
                    _busRouteInfo[bus] ?? "",
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            )).toList(),
            onChanged: (val) => setState(() => _selectedBusId = val!),
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
              ),
              onPressed: _createUser,
              child: const Text("CREATE USER ACCOUNT")),
        ],
      ),
    );
  }
}