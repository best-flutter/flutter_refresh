import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_refresh/src/refresh_child.dart';
import 'package:flutter_refresh/src/refresh_controller.dart';
import 'package:flutter_refresh/src/refresh_widget.dart';

///Only support 3 types of direct child
bool checkChild(Widget src) {
  switch (src.runtimeType) {
    case GridView:
    case SingleChildScrollView:
    case ListView:
      {
        return true;
      }
  }

  return false;
}

typedef Widget RefreshScrollViewBuilder(BuildContext context,
    {ScrollController controller, ScrollPhysics physics});

class Refresh extends StatefulWidget {
  final RefresherCallback onHeaderRefresh;
  final RefresherCallback onFooterRefresh;
  final RefreshController controller;
  final ScrollController scrollController;
  final RefreshScrollViewBuilder childBuilder;
  final ScrollPhysics physics;
  final Widget child;

  static ScrollPhysics createScrollPhysics(ScrollPhysics src) {
    if (Platform.isAndroid) {
      ScrollPhysics physics = new AlwaysScrollableScrollPhysics()
          .applyTo(new BouncingScrollPhysics());
      if (src != null) {
        return physics.applyTo(src);
      }
      return physics;
    }
    return src;
  }

  Refresh(
      {Key key,
      this.childBuilder,
      this.scrollController,
      this.onHeaderRefresh,
      this.child,
      this.controller,
      this.physics,
      this.onFooterRefresh})
      : super(key: key) {
    if (child != null) {
      assert(
          checkChild(child),
          "child must be GridView,SingleChildScrollView,ListView,"
          "if you want to put scrollview into another container, please use Refresh.builder instead");
    }

    if (childBuilder == null && child == null) {
      throw new Exception("childBuild or child must not be both null");
    }
  }
//
//  factory Refresh.singleChild(
//      {Key key, Widget child, RefreshScrollViewBuilder childBuilder}) {
//    assert(
//        checkChild(child),
//        "child must be GridView,SingleChildScrollView,ListView,"
//        "if you want to put scrollview into another container, please use Refresh.builder instead");
//
//    return new Refresh(
//      key: key,
//      childBuilder: childBuilder,
//    );
//  }

  @override
  State<StatefulWidget> createState() {
    return new _RefreshState();
  }
}

typedef void StateHandler(ScrollNotification notification);

class _RefreshState extends State<Refresh> with TickerProviderStateMixin {
  double _headerRefreshOffset = 50.0;
  double _footerRefreshOffset = 50.0;

  RefreshWidgetController _headerValue;
  RefreshWidgetController _footerValue;

  _RefreshHandler _headerHandler;
  _RefreshHandler _footerHandler;

  ScrollController controller;
  StateHandler _handler;

  bool _isAnimation = false;
  bool _animationComplete = false;

  void _scrollToAnimationFirst(double offset) {
    if (!_isAnimation) {
      if (_animationComplete) {
        controller.jumpTo(offset);
      } else {
        _isAnimation = true;
        controller
            .animateTo(offset,
                duration: new Duration(milliseconds: 300), curve: Curves.ease)
            .whenComplete(() {
          _isAnimation = false;
          _animationComplete = true;
        });
      }
    }
  }

  void _loading(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      assert(_refreshHandle != null);
      _scrollToAnimationFirst(
          _refreshHandle.getScrollOffset(notification.metrics));
    } else if (notification is ScrollStartNotification) {
      ScrollStartNotification startNotification = notification;
      if (startNotification.dragDetails != null) {
        _handler = _drag;
      }
      //

    }

    /// 如果这个时候有drag?
  }

  ///
  ///  State machine:
  ///
  /// Darg(User drag screen)
  /// =>Ready
  /// =>Loading(User end drag and  the condition is ok)
  /// =>Cancel(User end drag and the condition is not ok)
  /// =>End ( complete the action)
  ///
  /// The State convertion :
  ///
  ///   1 End=>Drag            when the state is End and user begin to drag(notification is ScrollStartNotification)
  ///   2 Drag=>Loading/Cancel    Two loading: head or foot,  condition: when user end drag
  ///   3 Loading=>Cancels         The callback has been called
  ///   4 Cancel =>End
  ///
  ///
  bool _handleScrollNotification(ScrollNotification notification) {
    _handler(notification);
    return false;
  }

  void _end(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        // print("drag start");
        _handler = _drag;
        _animationComplete = false;
      }
    }
  }

  _RefreshHandler _refreshHandle;

  void _drag(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      ScrollMetrics metrics = notification.metrics;
      if (notification.dragDetails != null) {
        double moveValue;
        if (_headerHandler != null &&
            (moveValue = _headerHandler.getRefreshWidgetMoveValue(metrics)) >
                0) {
          _refreshHandle = _headerHandler;
        } else if (_footerHandler != null &&
            (moveValue = _footerHandler.getRefreshWidgetMoveValue(metrics)) >
                0) {
          _refreshHandle = _footerHandler;
        } else {
          _refreshHandle = null;
        }
        if (_refreshHandle != null) {
          if (_refreshHandle.isReady(moveValue)) {
            _refreshHandle.changeState(RefreshState.ready);
          } else {
            _refreshHandle.changeState(RefreshState.drag);
          }
          _refreshHandle.controller.value = moveValue;
        }
      } else {
        if (_refreshHandle != null &&
            _refreshHandle
                .isReady(_refreshHandle.getRefreshWidgetMoveValue(metrics))) {
          _enterLoading(_refreshHandle, metrics);

          _isAnimation = false;
          _animationComplete = false;
          _handler = _loading;
          return;
        }
        _handler = _end;
      }
    }
  }

  void _enterLoading(
      _RefreshHandler _refreshHandle, ScrollMetrics metrics) async {
    double maxExtent;

    if (_refreshHandle == _footerHandler) {
      maxExtent = controller.position.maxScrollExtent;
    }

    try {
      await _refreshHandle.loading(metrics);
      _refreshHandle.controller.onSuccess();
    } catch (e) {
      _refreshHandle.controller.onError(e);
    } finally {
      if (_refreshHandle == _footerHandler) {
        controller.jumpTo(maxExtent - _footerRefreshOffset * 2);
      }
      _refreshHandle = null;
      _handler = _end;
    }
  }

  @override
  void initState() {
    super.initState();

    _handler = _end;
  }

  ScrollController _tryGetController(Widget src) {
    switch (src.runtimeType) {
      case GridView:
      case ListView:
        {
          return (src as BoxScrollView).controller;
        }

      case SingleChildScrollView:
        return (src as SingleChildScrollView).controller;
    }

    return null;
  }

  void _updateState() {
    if (widget.onHeaderRefresh != null) {
      if (_headerValue == null) _headerValue = new RefreshWidgetController();
      if (_headerHandler == null ||
          _headerHandler.callback != widget.onHeaderRefresh) {
        _headerHandler = new _RefreshHeaderHandler(
            controller: _headerValue,
            callback: widget.onHeaderRefresh,
            offset: _headerRefreshOffset);
      }
    } else {
      if (_headerValue != null) _headerValue.dispose();
      _headerHandler = null;
    }

    if (widget.onFooterRefresh != null) {
      if (_footerValue == null) _footerValue = new RefreshWidgetController();
      if (_footerHandler == null ||
          _footerHandler.callback != widget.onFooterRefresh) {
        _footerHandler = new _RefreshFooterHandler(
            controller: _footerValue,
            callback: widget.onFooterRefresh,
            offset: _footerRefreshOffset);
      }
    } else {
      if (_footerValue != null) _footerValue.dispose();
      _footerHandler = null;
    }

    ScrollController controller = widget.scrollController;
    if (controller == null) {
      if (widget.child != null) {
        controller = _tryGetController(widget.child);
      }
    }

    if (controller == null) {
      if (this.controller == null) {
        this.controller = new ScrollController();
      } else {
        //不动
      }
    } else {
      //不等于,是否要移除什么
      this.controller = controller;
    }
  }

  @override
  void didChangeDependencies() {
    _updateState();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(Refresh oldWidget) {
    _updateState();
    super.didUpdateWidget(oldWidget);
  }

  Widget _cloneChild(Widget src) {
    switch (src.runtimeType) {
      case GridView:
        {
          GridView listView = src as GridView;
          return new GridView.custom(
            gridDelegate: listView.gridDelegate,
            childrenDelegate: listView.childrenDelegate,
            controller: controller,
            physics: Refresh.createScrollPhysics(listView.physics),
            key: listView.key,
            scrollDirection: listView.scrollDirection,
          );
        }
        break;
      case SingleChildScrollView:
        {
          SingleChildScrollView listView = src as SingleChildScrollView;
          return new SingleChildScrollView(
            controller: controller,
            physics: Refresh.createScrollPhysics(listView.physics),
            key: listView.key,
            scrollDirection: listView.scrollDirection,
          );
        }
        break;
      case ListView:
        {
          ListView listView = src as ListView;
          return new ListView.custom(
            childrenDelegate: listView.childrenDelegate,
            controller: controller,
            physics: Refresh.createScrollPhysics(listView.physics),
            key: listView.key,
            scrollDirection: listView.scrollDirection,
          );
        }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget notificationChild = new NotificationListener(
      child: widget.child == null
          ? widget.childBuilder(context,
              controller: controller,
              physics: Refresh.createScrollPhysics(widget.physics))
          : _cloneChild(widget.child),
      onNotification: _handleScrollNotification,
    );

    List<Widget> children = [notificationChild];

    if (widget.onHeaderRefresh != null) {
      children.add(new RefreshWidget(
        height: _headerRefreshOffset,
        controller: _headerValue,
        createTween: createTweenForHeader,
        alignment: Alignment.topCenter,
        childBuilder:
            (BuildContext context, RefreshWidgetController controller) {
          return new DefaultRefreshChild(
            controller: controller,
            icon: new Icon(Icons.arrow_downward),
            up: true,
          );
        },
      ));
    }

    if (widget.onFooterRefresh != null) {
      children.add(new RefreshWidget(
        height: _footerRefreshOffset,
        controller: _footerValue,
        createTween: createTweenForFooter,
        alignment: Alignment.bottomCenter,
        childBuilder:
            (BuildContext context, RefreshWidgetController controller) {
          return new DefaultRefreshChild(
            controller: controller,
            icon: new Icon(Icons.arrow_upward),
            showLastUpdate: false,
            up: false,
          );
        },
      ));
    }

    return new Stack(
      key: widget.key,
      children: children,
    );
  }
}

abstract class _RefreshHandler {
  final RefreshWidgetController controller;
  final RefresherCallback callback;
  final double offset;

  RefreshState _state = RefreshState.drag;

  _RefreshHandler({this.controller, this.callback, this.offset});

  double getScrollOffset(ScrollMetrics metrics);

  double getRefreshWidgetMoveValue(ScrollMetrics metrics);

  Future<Null> loading(ScrollMetrics metrics) {
    changeState(RefreshState.loading);
    dynamic result = callback();
    assert(
        result is Future,
        "In this version,the call back must return a Future.value(null),  "
        "\n If the app is doing some working in the closure, the closure must define like this : "
        " \n Future<Null> onHeaderRefresh()  async {\n"
        "  await network.doSomeWork(); return new Future.value(null);"
        "\n } ");
    {
      result.whenComplete(() {
        changeState(RefreshState.drag);
      });
    }
    return result;
  }

  bool isReady(double moveValue) {
    return moveValue > offset;
  }

  void changeState(RefreshState currentState) {
    if (_state != currentState) {
      //通知状态改变
      _state = currentState;

      controller.state = _state;
    }
  }

  void cancel(ScrollMetrics metrics);
}

class _RefreshFooterHandler extends _RefreshHandler {
  _RefreshFooterHandler(
      {RefreshWidgetController controller,
      RefresherCallback callback,
      double offset: 50.0})
      : super(controller: controller, callback: callback, offset: offset);

  //When loading start, what value is ScrollView pixils?
  @override
  double getScrollOffset(ScrollMetrics metrics) {
    return metrics.maxScrollExtent + offset;
  }

  @override
  double getRefreshWidgetMoveValue(ScrollMetrics metrics) {
    return metrics.pixels - metrics.maxScrollExtent;
  }

  @override
  void cancel(ScrollMetrics metrics) {
    controller.value = metrics.pixels;
  }
}

class _RefreshHeaderHandler extends _RefreshHandler {
  _RefreshHeaderHandler(
      {RefreshWidgetController controller,
      RefresherCallback callback,
      double offset: 50.0})
      : super(controller: controller, callback: callback, offset: offset);

  //When loading start, what value is ScrollView pixils?
  @override
  double getScrollOffset(ScrollMetrics metrics) {
    return -offset;
  }

  @override
  void cancel(ScrollMetrics metrics) {
    controller.value = metrics.pixels;
  }

  @override
  double getRefreshWidgetMoveValue(ScrollMetrics metrics) {
    return -metrics.pixels;
  }
}
