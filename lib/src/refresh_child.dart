import 'refresh_widget.dart';
import 'package:flutter/material.dart';

class DefaultRefreshLocal {
  static DefaultRefreshLocal en(
          {String loading: "loading...",
          String error: 'load error...',
          String pullDownToRefresh: "pull down to refresh",
          String pullUpToRefresh: "pull up to refresh",
          String releaseToRefresh: "release to refresh",
          String lastUpdate = "last update"}) =>
      new DefaultRefreshLocal(
          error: error,
          lastUpdate: lastUpdate,
          loading: loading,
          releaseToRefresh: releaseToRefresh,
          pullDownToRefresh: pullDownToRefresh,
          pullUpToRefresh: pullUpToRefresh);

  static DefaultRefreshLocal zh(
          {String loading: "加载中...",
          String error: "加载失败...",
          String pullDownToRefresh: "下拉刷新",
          String pullUpToRefresh: "上拉加载更多",
          String releaseToRefresh: "放开加载",
          String lastUpdate = "最后更新"}) =>
      new DefaultRefreshLocal(
          error: error,
          lastUpdate: lastUpdate,
          loading: loading,
          releaseToRefresh: releaseToRefresh,
          pullDownToRefresh: pullDownToRefresh,
          pullUpToRefresh: pullUpToRefresh);

  final String loading;
  final String pullDownToRefresh;
  final String pullUpToRefresh;
  final String releaseToRefresh;
  final String lastUpdate;
  final String error;

  const DefaultRefreshLocal(
      {this.lastUpdate,
      this.error,
      this.loading,
      this.pullUpToRefresh,
      this.pullDownToRefresh,
      this.releaseToRefresh});
}

typedef RefreshChild RefreshChildBuilder(
    BuildContext context, RefreshWidgetController controller);

abstract class RefreshChild extends StatefulWidget {
  final RefreshWidgetController controller;

  RefreshChild({this.controller});

  @override
  State<StatefulWidget> createState();
}

class DefaultRefreshChild extends RefreshChild {
  final bool showState;
  final bool showLastUpdate;
  final Widget icon;
  final DefaultRefreshLocal local;
  final bool up;

  DefaultRefreshChild({
    RefreshWidgetController controller,
    this.showState: true,
    this.showLastUpdate: true,
    this.icon,
    DefaultRefreshLocal local,
    this.up: true,
  })  : this.local = local == null ? DefaultRefreshLocal.zh() : local,
        super(controller: controller);

  @override
  State<StatefulWidget> createState() {
    return new _DefaultRefreshHeaderState();
  }
}

class _DefaultRefreshHeaderState extends State<DefaultRefreshChild>
    with TickerProviderStateMixin {
  AnimationController _animation;

  Tween<double> _tween;

  DateTime _lastUpdate;

  RefreshState _state = RefreshState.drag;

  String _formateDate() {
    DateTime time = _lastUpdate;
    return " ${_twoDigist(time.hour)}:${_twoDigist(time.minute)}";
  }

  static String _twoDigist(int num) {
    if (num < 10) return "0$num";
    return num.toString();
  }

  @override
  void initState() {
    super.initState();

    _animation = new AnimationController(vsync: this);
    _tween = new Tween<double>(
      begin: 0.0,
      end: 1.0,
    );
    _tween.animate(_animation);
    _lastUpdate = new DateTime.now();
  }

  void _rotate(double value, bool releaseToRefresh) {
    _animation
        .animateTo(value,
            duration: new Duration(milliseconds: 200), curve: Curves.ease)
        .whenComplete(() {});
  }

  void _updateState() {
    switch (widget.controller.state) {
      case RefreshState.ready:
        {
          _rotate(0.5, true);
        }

        break;

      case RefreshState.drag:
        {
          _rotate(0.0, true);
        }

        break;
      case RefreshState.loading:
        {}
        break;
      case RefreshState.success:
        {}
        break;
      case RefreshState.error:
        {}
        break;
    }

    setState(() {
      _state = widget.controller.state;
    });
  }

  @override
  void didChangeDependencies() {
    widget.controller.addStateListener(_updateState);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(RefreshChild oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeStateListener(_updateState);
      widget.controller.addStateListener(_updateState);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeStateListener(_updateState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style =
        Theme.of(context).textTheme.body1; // //new TextStyle(fontSize: 14.0);

    String stateText;
    switch (_state) {
      case RefreshState.loading:
        stateText = widget.local.loading;
        break;
      case RefreshState.ready:
        stateText = widget.local.releaseToRefresh;
        break;
      case RefreshState.drag:
      case RefreshState.success:
        stateText = (widget.up
            ? widget.local.pullDownToRefresh
            : widget.local.pullUpToRefresh);
        break;
      case RefreshState.error:
        stateText = widget.local.error;
        break;
    }

    List<Widget> texts = [];
    if (widget.showState) {
      texts.add(
        new Text(
          stateText,
          style: style,
        ),
      );
    }

    if (widget.showLastUpdate) {
      texts.add(new Text(
        "${widget.local.lastUpdate} ${_formateDate()}",
        style: style,
      ));
    }

    Widget text = texts.length > 0
        ? new Padding(
            padding: new EdgeInsets.only(left: 10.0),
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: texts,
            ),
          )
        : null;

    List<Widget> row = [
      _state == RefreshState.loading
          ? new SizedBox(
              width: 20.0, height: 20.0, child: new CircularProgressIndicator())
          : new RotationTransition(
              turns: _animation,
              child: widget.icon,
            ),
    ];

    if (text != null) {
      row.add(text);
    }

    return new Row(
      mainAxisSize: MainAxisSize.min,
      children: row,
    );
  }
}
