import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gesture/di/providers.dart';
import 'package:gesture/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _roomIdController = TextEditingController();

  Future<void> _connect() async {
    if (_formKey.currentState?.validate() == true) {
      await ref
          .read(connectViewModelProvider.notifier)
          .createJoinToken(username: _usernameController.text, roomId: _roomIdController.text);
    } else {
      print('invalid connect values');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _showFailureDialog(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Failure'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Unable to connect.'),
              Text('Please try again.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectViewModelProvider);

    ref.listen(connectViewModelProvider, (previous, next) {
      if (previous?.isLoading == true && next?.isLoading == false) {
        if (next?.hasError == false) {
          unawaited(context.push(Routes.prejoin));
        } else if (next?.hasError == true) {
          unawaited(_showFailureDialog(context));
        }
      }
    });

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Gesture')),
          body: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Username'),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                    controller: _usernameController,
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Room'),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the ID of the room you would like to join';
                      }
                      return null;
                    },
                    controller: _roomIdController,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state?.isLoading == true ? null : _connect,
                    child: const Text('Connect'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state?.isLoading == true)
          Container(
            color: Colors.black54,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
