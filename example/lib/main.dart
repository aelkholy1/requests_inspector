import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:requests_inspector/inspector_controller.dart';
import 'package:requests_inspector/request_details.dart';

import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/requests_methods.dart';

Future<List<Post>> fetchPosts() async {
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  final response = await dio.get('https://jsonplaceholder.typicode.com/posts');

  final postsMap = response.data as List;
  final posts = postsMap.map((postMap) => Post.fromMap(postMap)).toList();

  InspectorController().addNewRequest(
    RequestDetails(
      requestName: 'Posts', //Optional
      requestMethod: RequestMethod.GET,
      url: 'https://jsonplaceholder.typicode.com/posts',
      statusCode: response.statusCode ?? 0,
      responseBody: response.data,
      sentTime: DateTime.now(),
    ),
  );

  return posts;
}

class Post {
  final int userId;
  final int id;
  final String title;
  final String body;
  Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  Post copyWith({
    int? userId,
    int? id,
    String? title,
    String? body,
  }) {
    return Post(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'id': id,
      'title': title,
      'body': body,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      userId: map['userId']?.toInt() ?? 0,
      id: map['id']?.toInt() ?? 0,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Post.fromJson(String source) => Post.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Post(userId: $userId, id: $id, title: $title, body: $body)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Post &&
        other.userId == userId &&
        other.id == id &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ id.hashCode ^ title.hashCode ^ body.hashCode;
  }
}

void main() => runApp(
      const RequestsInspector(
        enabled: true,
        child: MyApp(),
      ),
    );

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Post>> futurePosts;

  @override
  void initState() {
    super.initState();
    futurePosts = fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fetch Data Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fetch Data Example'),
        ),
        body: Center(
          child: FutureBuilder<List<Post>>(
            future: futurePosts,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return PostsListWidget(postsList: snapshot.data!);
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}

class PostsListWidget extends StatelessWidget {
  const PostsListWidget({Key? key, required this.postsList}) : super(key: key);

  final List<Post> postsList;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchPosts,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: postsList.length,
        itemBuilder: _buildPostItem,
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, int index) {
    final post = postsList[index];
    return ListTile(
      leading: Text(post.id.toString()),
      title: Text(post.title),
      subtitle: Text(post.body),
    );
  }
}