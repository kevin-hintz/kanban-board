import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc.dart';
import 'kanban.dart';

/// --- Main App --- ///

void main() {
  runApp(const MyApp());
}

/// The root widget sets up the BlocProvider.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kanban Board',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      home: BlocProvider(
        create: (_) => KanbanBoardBloc(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Kanban Board'),
            foregroundColor: Colors.black87,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: KanbanBoardWidget(),
          ),
        ),
      ),
    );
  }
}
