import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  String bookName;
  String authorName;

  DocumentReference documentReference;

  Book({this.bookName, this.authorName});

  Book.fromMap(Map<String, dynamic> map, {this.documentReference}) {
    bookName = map["bookName"]; //Object in class => Db value name
    authorName = map["authorName"];
  }

  Book.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), documentReference: snapshot.reference);

  toJson() {
    //send to db
    return {'bookName': bookName, 'authorName': authorName};
  }
}
