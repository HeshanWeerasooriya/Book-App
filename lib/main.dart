import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'models/book.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(BookApp());
}

class BookApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BookApp',
      home: FireBook(),
    );
  }
}

class FireBook extends StatefulWidget {
  FireBook() : super();
  final String appTitle = "Book DB";
  @override
  _FireBookState createState() => _FireBookState();
}

class _FireBookState extends State<FireBook> {
  TextEditingController bookNameController = TextEditingController();
  TextEditingController bookAuthorController = TextEditingController();

  bool isEditing = false;
  bool textFieldVisibility = false;

  String firestoreCollectionName = "Books";

  Book currentBook; //Book that ready to update

  getAllBooks() {
    return FirebaseFirestore.instance
        .collection(firestoreCollectionName)
        .snapshots();
  }

  addBook() {
    Book book = Book(
        bookName: bookNameController.text,
        authorName: bookAuthorController.text);

    try {
      FirebaseFirestore.instance
          .runTransaction((Transaction transaction) async {
        await FirebaseFirestore.instance
            .collection(firestoreCollectionName)
            .doc()
            .set(book.toJson());
      });
    } catch (e) {
      print(e.toString());
    }
  }

  updateBook(Book book, String bookName, String authorName) {
    try {
      FirebaseFirestore.instance.runTransaction((transaction) async {
        await transaction.update(book.documentReference,
            {'bookName': bookName, 'authorName': authorName});
      });
    } catch (e) {
      print(e.toString());
    }
  }

  updateIfEditing() {
    if (isEditing) {
      updateBook(
          currentBook, bookNameController.text, bookAuthorController.text);

      setState(() {
        isEditing = false;
      });
    }
  }

  deleteBook(Book book) {
    FirebaseFirestore.instance.runTransaction((transaction) async {
      await transaction.delete(book.documentReference);
    });
  }

  Widget buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: getAllBooks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error ${snapshot.error}');
        }
        if (snapshot.hasData) {
          print("Documents -> ${snapshot.data.docs.length}");
          return buildList(context, snapshot.data.docs);
        }
      },
    );
  }

  Widget buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      children: snapshot.map((data) => listItemBuild(context, data)).toList(),
    );
  }

  Widget listItemBuild(BuildContext context, DocumentSnapshot data) {
    final book = Book.fromSnapshot(data);

    return Padding(
      key: ValueKey(book.bookName),
      padding: EdgeInsets.symmetric(vertical: 19, horizontal: 1),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(5),
        ),
        child: SingleChildScrollView(
          child: ListTile(
            title: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.book),
                    Text(book.bookName ?? ""), //*
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Icon(Icons.person),
                    Text(book.authorName ?? ""),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  deleteBook(book);
                }),
            onTap: () {
              setUpdateUI(book);
            },
          ),
        ),
      ),
    );
  }

  void setUpdateUI(Book book) {
    bookNameController.text = book.bookName;
    bookAuthorController.text = book.authorName;

    setState(() {
      textFieldVisibility = true;
      isEditing = true;
      currentBook = book;
    });
  }

  button() {
    return SizedBox(
      width: double.infinity,
      child: OutlineButton(
        child: Text(isEditing ? "UPDATE" : "ADD"),
        onPressed: () {
          if (isEditing == true) {
            updateIfEditing();
          } else {
            addBook();
          }

          setState(() {
            textFieldVisibility = false;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.appTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                textFieldVisibility = !textFieldVisibility;
              });
            },
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            textFieldVisibility
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          TextFormField(
                            controller: bookNameController,
                            decoration: InputDecoration(
                                labelText: "Book Name",
                                hintText: "Enter Book Name"),
                          ),
                          TextFormField(
                            controller: bookAuthorController,
                            decoration: InputDecoration(
                                labelText: "Book Author",
                                hintText: "Enter Author Name"),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      button()
                    ],
                  )
                : Container(),
            SizedBox(
              height: 18,
            ),
            Text(
              "Books",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Flexible(
              child: buildBody(context),
            ),
          ],
        ),
      ),
    );
  }
}
