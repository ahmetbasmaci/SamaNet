import 'package:flutter/material.dart';
import 'dart:async';

/// Base class for all BLoCs - simplified implementation
abstract class BaseBloc {
  StreamController<dynamic>? _stateController;
  dynamic _currentState;

  BaseBloc(dynamic initialState) {
    _currentState = initialState;
    _stateController = StreamController<dynamic>.broadcast();
  }

  dynamic get state => _currentState;
  Stream<dynamic> get stream => _stateController!.stream;

  void emit(dynamic newState) {
    if (_stateController?.isClosed ?? true) return;
    _currentState = newState;
    _stateController!.add(newState);
  }

  void add(dynamic event) {
    // To be implemented by subclasses
  }

  void close() {
    _stateController?.close();
  }
}

/// Simple BLoC provider
class BlocProvider<T extends BaseBloc> extends InheritedWidget {
  final T bloc;

  const BlocProvider({super.key, required this.bloc, required super.child});

  @override
  bool updateShouldNotify(BlocProvider<T> oldWidget) => oldWidget.bloc != bloc;

  static T of<T extends BaseBloc>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<BlocProvider<T>>();
    if (provider == null) {
      throw Exception('BlocProvider<$T> not found in context');
    }
    return provider.bloc;
  }
}

/// BLoC builder widget
class BlocBuilder<T extends BaseBloc, S> extends StatefulWidget {
  final T bloc;
  final Widget Function(BuildContext context, S state) builder;

  const BlocBuilder({super.key, required this.bloc, required this.builder});

  @override
  State<BlocBuilder<T, S>> createState() => _BlocBuilderState<T, S>();
}

class _BlocBuilderState<T extends BaseBloc, S> extends State<BlocBuilder<T, S>> {
  late S currentState;
  late StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
    currentState = widget.bloc.state as S;
    subscription = widget.bloc.stream.listen((state) {
      if (mounted && state is S) {
        setState(() {
          currentState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, currentState);
  }
}

/// BLoC listener widget
class BlocListener<T extends BaseBloc, S> extends StatefulWidget {
  final T bloc;
  final void Function(BuildContext context, S state) listener;
  final Widget child;

  const BlocListener({super.key, required this.bloc, required this.listener, required this.child});

  @override
  State<BlocListener<T, S>> createState() => _BlocListenerState<T, S>();
}

class _BlocListenerState<T extends BaseBloc, S> extends State<BlocListener<T, S>> {
  late StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
    subscription = widget.bloc.stream.listen((state) {
      if (mounted && state is S) {
        widget.listener(context, state);
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
