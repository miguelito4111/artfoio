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



Widget _buildCategoryTab(String category) {
  return Column(
    children: [
      ElevatedButton(
        onPressed: () => _pickAndUploadImage(category),
        child: Text('Add Image'),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('images')
            .where('category', isEqualTo: category)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
} else if (snapshot.hasError) {
    return Center(child: Text('Error: ${snapshot.error}'));
} else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
  var doc = snapshot.data!.docs[index].data();
  var artistName = doc['artistName'] ?? 'Unknown Artist'; // Default value if null
  var imageUrl = doc['url'] as String;

  return Column(
    children: [
      Text(artistName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      GestureDetector(
        onTap: () => _showImageDialog(context, imageUrl),
        child: Container(
          height: 90, // Adjust based on your UI needs
          width: double.infinity,
          child: Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    ],
  );
},


    );
} else {
    return Center(child: Text('No images to display.'));
}

}

        ),
      ),
    ],
  );
}
          
        
  Widget _buildPhotographsTab() {
  return _buildCategoryTab("Photographs");
  }

  Widget _buildPaintingsTab() {
    return _buildCategoryTab("Paintings");
  }

  Widget _buildSculpturesTab() {
    return _buildCategoryTab("Sculptures");
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
void _showImageDialog(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Container(
          padding: EdgeInsets.all(10), // Reduce padding if necessary
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8), // Max height for the image
          child: Image.network(imageUrl, fit: BoxFit.contain), // Use BoxFit.contain to fit the image within the container
        ),
      );
    },
  );
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
void _pickAndUploadImage(String category) async {
  if (artistNameController.text.isEmpty) {
    // Handle the case where the artist name is not set
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Please set your artist name in your profile before uploading images."),
      duration: Duration(seconds: 3),
    ));
    return;
  }

  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    File imageFile = File(image.path);
    String imageUrl = await _uploadImageToCategoryFirebase(imageFile, category);
    _addImageToFirestore(imageUrl, category);
  }
}


Future<String> _uploadImageToCategoryFirebase(File imageFile, String category) async {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  FirebaseStorage storage = FirebaseStorage.instance;
  Reference ref = storage.ref().child('$category/$userId/${DateTime.now().millisecondsSinceEpoch}');
  UploadTask uploadTask = ref.putFile(imageFile);
  final TaskSnapshot downloadUrl = await uploadTask;
  return await downloadUrl.ref.getDownloadURL();
}

void _addImageToFirestore(String imageUrl, String category) {
  String artistName = artistNameController.text;
  FirebaseFirestore.instance.collection('images').add({
    'url': imageUrl,
    'category': category,
    'uploadedBy': FirebaseAuth.instance.currentUser!.uid,
    'artistName': artistName,  // Assuming you have the artist's name available
    'timestamp': FieldValue.serverTimestamp(),
  });
}


}




