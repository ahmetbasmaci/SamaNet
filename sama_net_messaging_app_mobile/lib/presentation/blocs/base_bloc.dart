import 'dart:async';
import 'package:flutter/material.dart';

/// Base class for all BLoC states
abstract class BlocState {}

/// Base class for all BLoC events
abstract class BlocEvent {}

/// Simple BLoC implementation without external dependencies
abstract class Bloc<Event extends BlocEvent, State extends BlocState> {
  final StreamController<State> _stateController = StreamController<State>.broadcast();
  late State _currentState;

  /// Constructor that requires an initial state
  Bloc(State initialState) {
    _currentState = initialState;
  }

  /// Stream of states
  Stream<State> get stream => _stateController.stream;

  /// Current state
  State get state => _currentState;

  /// Add an event to be processed
  void add(Event event) {
    try {
      mapEventToState(event);
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  /// Map events to states - to be implemented by subclasses
  void mapEventToState(Event event);

  /// Emit a new state
  void emit(State state) {
    if (_stateController.isClosed) return;

    _currentState = state;
    _stateController.add(state);
  }

  /// Handle errors
  void onError(Object error, StackTrace stackTrace) {
    debugPrint('BLoC Error: $error\n$stackTrace');
  }

  /// Close the bloc
  void close() {
    _stateController.close();
  }
}

/// Widget that builds UI based on BLoC state changes
class BlocBuilder<B extends Bloc<dynamic, S>, S extends BlocState> extends StatefulWidget {
  final B bloc;
  final Widget Function(BuildContext context, S state) builder;
  final bool Function(S previous, S current)? buildWhen;

  const BlocBuilder({super.key, required this.bloc, required this.builder, this.buildWhen});

  @override
  State<BlocBuilder<B, S>> createState() => _BlocBuilderState<B, S>();
}

class _BlocBuilderState<B extends Bloc<dynamic, S>, S extends BlocState> extends State<BlocBuilder<B, S>> {
  late S _previousState;
  late StreamSubscription<S> _subscription;

  @override
  void initState() {
    super.initState();
    _previousState = widget.bloc.state;
    _subscription = widget.bloc.stream.listen((state) {
      if (widget.buildWhen?.call(_previousState, state) ?? true) {
        setState(() {
          _previousState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.bloc.state);
  }
}

/// Widget that listens to BLoC state changes and calls a callback
class BlocListener<B extends Bloc<dynamic, S>, S extends BlocState> extends StatefulWidget {
  final B bloc;
  final void Function(BuildContext context, S state) listener;
  final bool Function(S previous, S current)? listenWhen;
  final Widget child;

  const BlocListener({super.key, required this.bloc, required this.listener, required this.child, this.listenWhen});

  @override
  State<BlocListener<B, S>> createState() => _BlocListenerState<B, S>();
}

class _BlocListenerState<B extends Bloc<dynamic, S>, S extends BlocState> extends State<BlocListener<B, S>> {
  late S _previousState;
  late StreamSubscription<S> _subscription;

  @override
  void initState() {
    super.initState();
    _previousState = widget.bloc.state;
    _subscription = widget.bloc.stream.listen((state) {
      if (widget.listenWhen?.call(_previousState, state) ?? true) {
        widget.listener(context, state);
        _previousState = state;
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Widget that provides a BLoC to its children
class BlocProvider<B extends Bloc<dynamic, dynamic>> extends InheritedWidget {
  final B bloc;

  const BlocProvider({super.key, required this.bloc, required super.child});

  static B of<B extends Bloc<dynamic, dynamic>>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<BlocProvider<B>>();
    if (provider == null) {
      throw Exception('BlocProvider<$B> not found in context');
    }
    return provider.bloc;
  }

  @override
  bool updateShouldNotify(BlocProvider<B> oldWidget) {
    return oldWidget.bloc != bloc;
  }
}
