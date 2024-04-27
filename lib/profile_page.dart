import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilesssssPage createState() => _ProfilesssssPage();
}

class _ProfilesssssPage extends State<StatefulWidget> {
  final TextEditingController artistNameController = TextEditingController();
  final TextEditingController occupationController = TextEditingController();
  final TextEditingController additionalInfoController = TextEditingController();
  File? _imageFile;
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _isProfileComplete ? 4 : 1, // Total tabs count
      child: Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          bottom: _isProfileComplete ? TabBar(
            tabs: [
              Tab(text: "Profile"),
              Tab(text: "Photographs"),
              Tab(text: "Paintings"),
              Tab(text: "Sculptures"),
            ],
          ) : null,
        ),
        body: TabBarView(
          children: _isProfileComplete
            ? [
                _buildProfileTab(),
                _buildPhotographsTab(),
                _buildPaintingsTab(),
                _buildSculpturesTab(),
              ]
            : [_buildProfileTab()],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
  return SingleChildScrollView(
    padding: EdgeInsets.all(16.0),
    child: FutureBuilder<DocumentSnapshot>(
      future: _fetchProfileData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          Map<String, dynamic>? profileData = snapshot.data?.data() as Map<String, dynamic>?;
          artistNameController.text = profileData?['artistName'] ?? '';
          occupationController.text = profileData?['occupation'] ?? '';
          additionalInfoController.text = profileData?['additionalInfo'] ?? '';
          String profileImageUrl = profileData?['profileImageUrl'] ?? '';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isProfileComplete)  // Conditional message display
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Center(
                    child: Text(
                      "Please complete your profile with your artist name, occupation, additional info, and a profile photo to access the portfolios.",
                      style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                      backgroundColor: Colors.grey,
                      child: profileImageUrl.isEmpty ? Icon(Icons.camera_alt, size: 30) : null,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: artistNameController,
                          decoration: InputDecoration(labelText: 'Artist Name'),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: occupationController,
                          decoration: InputDecoration(labelText: 'Occupation'),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: additionalInfoController,
                          decoration: InputDecoration(labelText: 'Additional Info'),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfileInfo,
                child: Text('Save Changes'),
              ),
            ],
          );
        }
        return Text('Please start by completing your profile.');
      },
    ),
  );
}




  Widget _buildPhotographsTab() {
    return Center(child: Text("Photographs"));
  }

  Widget _buildPaintingsTab() {
    return Center(child: Text("Paintings"));
  }

  Widget _buildSculpturesTab() {
    return Center(child: Text("Sculptures"));
  }

  void _checkProfileCompletion() async {
    DocumentSnapshot profileData = await _fetchProfileData();
    if (profileData.exists) {
      Map<String, dynamic> data = profileData.data() as Map<String, dynamic>;
      setState(() {
        _isProfileComplete = data['artistName'] != null && data['occupation'] != null && data['additionalInfo'] != null && data['profileImageUrl'] != null;
      });
    }
  }

Future<DocumentSnapshot> _fetchProfileData() async {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  return FirebaseFirestore.instance.collection('users').doc(userId).get();
}

void _pickImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    setState(() {
      _imageFile = File(image.path);
    });
    _uploadImageToFirebase();
  }
}

void _saveProfileInfo() async {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);

  // Prepare the data to update or set
  Map<String, dynamic> data = {
    'artistName': artistNameController.text.trim(),
    'occupation': occupationController.text.trim(),
    'additionalInfo': additionalInfoController.text.trim(),
  };

  // Check if an image was uploaded; otherwise, skip changing the image URL
  if (_imageFile != null) {
    String imageUrl = await _uploadImageToFirebase();
    if (imageUrl.isNotEmpty) {
      data['profileImageUrl'] = imageUrl;
    }
  }

  // Fetch the document to see if it exists
  DocumentSnapshot userDocSnapshot = await userDocRef.get();

  Future<void> operation;
  if (userDocSnapshot.exists) {
    // Document exists, update it
    operation = userDocRef.update(data);
  } else {
    // Document does not exist, create it with a placeholder for profile image if not set
    if (data['profileImageUrl'] == null) {
      data['profileImageUrl'] = '';
    }
    operation = userDocRef.set(data);
  }

  operation.then((_) async {
    // After the operation, check if the profile is complete
    bool isComplete = data['artistName'].isNotEmpty &&
                      data['occupation'].isNotEmpty &&
                      data['additionalInfo'].isNotEmpty &&
                      data.containsKey('profileImageUrl') && data['profileImageUrl'].isNotEmpty;

    if (isComplete) {
      setState(() {
        _isProfileComplete = true;
      });
    }
  }).catchError((error) {
    print("Error updating or creating document: $error");
  });
}

Future<String> _uploadImageToFirebase() async {
  if (_imageFile == null) return '';
  String userId = FirebaseAuth.instance.currentUser!.uid;
  FirebaseStorage storage = FirebaseStorage.instance;
  Reference ref = storage.ref().child('profile_images/$userId');
  UploadTask uploadTask = ref.putFile(_imageFile!);
  final TaskSnapshot downloadUrl = await uploadTask;
  return await downloadUrl.ref.getDownloadURL();
}


}




