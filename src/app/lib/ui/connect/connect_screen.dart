import 'dart:async';
import 'dart:math';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 600.0 ? 600.0 : null;
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: Image.asset(
                  'assets/images/logo_title.png',
                  height: 40, // constrain height to fit the AppBar
                  fit: BoxFit.contain,
                ),
                centerTitle: true,
              ),
              body: Center(
                child: Container(
                  width: maxWidth,
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Connect to your room',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 28),
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
      },
    );
  }
}
