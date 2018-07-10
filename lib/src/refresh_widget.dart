import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_refresh/src/refresh_child.dart';
import 'dart:math' as Math;

typedef Future<Null> RefresherCallback();

enum RefreshState {
  //User is dragging the ScrollView,but the offset is not enough
  drag,
  //User is dragging the ScrollView,and the offset is enough
  ready,
  //User has released dragging
  loading,
  //reset the position
  success,
  //error
  error,
}

///refresh componet
class RefreshWidgetController extends ValueNotifier<double> {
  RefreshWidgetController()
      : _state = new ValueNotifier(RefreshState.drag),
        super(0.0);

  final ValueNotifier<RefreshState> _state;

  bool get loading => _state.value == RefreshState.loading;

  set state(RefreshState state) {
    _state.value = state;
  }

  RefreshState get state => _state.value;

  @override
  double get value => super.value;

  @override
  set value(double newValue) {
    if (loading) return;
    super.value = newValue;
  }

  void onSuccess() {
    this.state = RefreshState.success;
  }

  void addStateListener(VoidCallback updateState) {
    _state.addListener(updateState);
  }

  void removeStateListener(VoidCallback updateState) {
    _state.removeListener(updateState);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void onError(e) {
    _state.value = RefreshState.error;
  }
}

typedef RectTween CreateTween(RefreshWidget widget);

RectTween createTweenForHeader(RefreshWidget widget) {
  return new RectTween(
    begin: new Rect.fromLTRB(0.0, -widget.height, 0.0, 0.0),
    end: new Rect.fromLTRB(0.0, 300.0, 0.0, 0.0),
  );
}

RectTween createTweenForFooter(RefreshWidget widget) {
  return new RectTween(
    begin: new Rect.fromLTRB(0.0, 0.0, 0.0, widget.height),
    end: new Rect.fromLTRB(0.0, 0.0, 0.0, -300.0),
  );
}

class RefreshWidget extends StatefulWidget {
  final double height;

  final double maxOffset = 300.0;

  final RefreshChildBuilder childBuilder;

  final RefreshWidgetController controller;

  final CreateTween createTween;

  final AlignmentGeometry alignment;

  RefreshWidget(
      {this.height,
      this.controller,
      this.childBuilder,
      this.createTween,
      this.alignment})
      : assert(controller != null);

  @override
  State<StatefulWidget> createState() {
    return new _RefreshHeaderState();
  }
}

class _RefreshHeaderState extends State<RefreshWidget>
    with TickerProviderStateMixin {
  //The animation controller to control the widtet's position
  AnimationController _positionController;
  //
  Animation<Rect> _positionFactor;

  @override
  void initState() {
    super.initState();
    _positionController = new AnimationController(vsync: this);
    _positionFactor = widget.createTween(widget).animate(_positionController);
  }

  ///End=>Loading=>End
  void _updateValue() {
    double value = Math.min(widget.controller.value, widget.height) /
        (widget.maxOffset + widget.height);
    //let's move head
    _positionController.value = value;
  }

  void _updateState() {
    switch (widget.controller.state) {
      case RefreshState.drag:
        break;
      case RefreshState.loading:
        {
          double value = widget.height / (widget.maxOffset + widget.height);
          _positionController
              .animateTo(value,
                  duration: new Duration(milliseconds: 300), curve: Curves.ease)
              .whenComplete(() {});
        }
        break;
      case RefreshState.ready:
        break;
      case RefreshState.error:
      case RefreshState.success:
        _positionController
            .animateTo(0.0,
                duration: new Duration(milliseconds: 300), curve: Curves.ease)
            .whenComplete(() {});
        break;
    }
  }

  @override
  void didChangeDependencies() {
    widget.controller.addListener(_updateValue);
    widget.controller.addStateListener(_updateState);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(RefreshWidget oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateValue);
      oldWidget.controller.removeStateListener(_updateState);
      widget.controller.addListener(_updateValue);
      widget.controller.addStateListener(_updateState);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateValue);
    widget.controller.removeStateListener(_updateState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RefreshWidget widget = this.widget;
    return new RelativePositionedTransition(
        size: new Size(0.0, 0.0),
        rect: _positionFactor,
        child: new AnimatedBuilder(
            animation: _positionController,
            builder: (BuildContext context, Widget child) {
              return new Align(
                child: new SizedBox(
                  height: widget.height,
                  child: this.widget.childBuilder(context, widget.controller),
                ),
                alignment: widget.alignment,
              );
            }));
  }
}
