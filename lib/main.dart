import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:contacts_service/contacts_service.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSplashScreen(
        splash: Image.asset("assets/Dialmate.png"),
        nextScreen: MyHomePage(title: 'Flutter Contacts'), // Provide a valid title here
        splashTransition: SplashTransition.fadeTransition,
        duration: 3000,
        backgroundColor: Colors.white,
        // Adjust the duration as needed (in milliseconds)
      ),
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchContacts();
    searchController.addListener(() {
      filterContacts();
    });
  }

  String? flattenPhoneNumber(String? phoneStr) {
    if (phoneStr == null) return null;
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }


  filterContacts() {
    List<Contact> _contacts = List.from(contacts);
    if (searchController.text.isNotEmpty) {
      _contacts.retainWhere((contact) {
        String searchTerm = searchController.text.toLowerCase();
        String searchTermFlatten = flattenPhoneNumber(searchTerm) ?? '';
        String contactName = contact.displayName?.toLowerCase() ?? '';
        bool nameMatches = contactName.contains(searchTerm);
        if (nameMatches) {
          return true;
        }
        if (searchTermFlatten.isEmpty) {
          return false;
        }
        var phone = contact.phones?.firstWhere(
              (phn) => flattenPhoneNumber(phn.value)?.contains(searchTermFlatten) ?? false,
          orElse: () => Item(label: 'None', value: 'None'), // Provide a default Item here
        );
        return phone != null;
      });
    }
    setState(() {
      contactsFiltered = _contacts;
    });
  }

  Future<void> fetchContacts() async {
    // Check if the permission is granted, if not, request it.
    if (await _hasReadContactsPermission()) {
      try {
        Iterable<Contact> _contacts = await ContactsService.getContacts();
        setState(() {
          contacts = _contacts.toList();
        });
      } catch (e) {
        print("Error fetching contacts: ${e.toString()}");
      }
    } else {
      await _requestReadContactsPermission();
    }
  }

  // Method to check if READ_CONTACTS permission is granted
  Future<bool> _hasReadContactsPermission() async {
    var status = await Permission.contacts.status;
    return status.isGranted;
  }

  // Method to request READ_CONTACTS permission
  Future<void> _requestReadContactsPermission() async {
    var status = await Permission.contacts.request();
    if (status.isGranted) {
      fetchContacts();
    } else {
      print("Error requesting contacts permission.");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchController.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColorDark,
        onPressed: () async {
          try {
            Contact? contact = await ContactsService.openContactForm();
            if (contact != null) {
              fetchContacts();
            }
          } on FormOperationException catch (e) {
            switch (e.errorCode) {
              case FormOperationErrorCode.FORM_OPERATION_CANCELED:
              case FormOperationErrorCode.FORM_COULD_NOT_BE_OPEN:
                print(e.toString());
                break;
              default:
                print('An unknown error occurred: ${e.toString()}');
                break;
            }
          }
        },
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Container(
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  filterContacts(); // Call filterContacts() when the text changes
                },
                decoration: InputDecoration(
                  labelText: "Search",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: isSearching ? contactsFiltered.length : contacts.length,
                itemBuilder: (context, index) {
                  if (isSearching) {
                    if (contactsFiltered.isEmpty) {
                      return ListTile(
                        title: Text('No Contacts'),
                        subtitle: Text('No Phone Number'),
                      );
                    } else {
                      Contact contact = contactsFiltered[index];
                      String phoneNumber = contact.phones?.isNotEmpty == true
                          ? contact.phones!.elementAt(0).value ?? 'No Phone Number'
                          : 'No Phone Number';

                      return GestureDetector(
                        onTap: () {
                          _updateContact(contact); // Handle tap to update contact
                        },
                        child: ListTile(
                          title: Text(contact.displayName ?? ''),
                          subtitle: Text(phoneNumber),
                          leading: (contact.avatar != null && contact.avatar!.isNotEmpty)
                              ? CircleAvatar(
                            backgroundImage: MemoryImage(contact.avatar!),
                          )
                              : CircleAvatar(child: Text(contact.initials())),
                        ),
                      );
                    }
                  } else {
                    if (contacts.isEmpty) {
                      return ListTile(
                        title: Text('No Contacts'),
                        subtitle: Text('No Phone Number'),
                      );
                    } else {
                      Contact contact = contacts[index];
                      String phoneNumber = contact.phones?.isNotEmpty == true
                          ? contact.phones!.elementAt(0).value ?? 'No Phone Number'
                          : 'No Phone Number';

                      return GestureDetector(
                        onTap: () {
                          _updateContact(contact); // Handle tap to update contact
                        },
                        child: ListTile(
                          title: Text(contact.displayName ?? ''),
                          subtitle: Text(phoneNumber),
                          leading: (contact.avatar != null && contact.avatar!.isNotEmpty)
                              ? CircleAvatar(
                            backgroundImage: MemoryImage(contact.avatar!),
                          )
                              : CircleAvatar(child: Text(contact.initials())),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateContact(Contact contact) async {
    try {
      Contact? updatedContact = await ContactsService.openExistingContact(contact);
      if (updatedContact != null) {
        // Handle the updated contact data (e.g., update it in your contact list)
        // Handle the updated contact data (e.g., update it in your contact list)
        updateContactInList(updatedContact);

        // Show a SnackBar to indicate that the contact was updated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FormOperationException catch (e) {
      // Handle any form operation errors here
      print('Error updating contact: ${e.toString()}');
    }
  }

  void updateContactInList(Contact updatedContact) {
    // Find and update the contact in your contacts list
    final index = contacts.indexWhere((c) => c.identifier == updatedContact.identifier);
    if (index != -1) {
      setState(() {
        contacts[index] = updatedContact;
      });
    }
  }
}