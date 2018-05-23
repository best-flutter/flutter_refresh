import 'package:flutter/material.dart';
/**
 *
 */
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_refresh/flutter_refresh.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Pull to refresh'),
      localizationsDelegates: [
        //   Refresh.delegate()
      ],
      routes: {
        'route':(BuildContext context){
          return null;
        },
      }
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Widget _itemBuilder(BuildContext context, int index) {
    return new Padding(
      key: new Key(index.toString()),
      padding: new EdgeInsets.all(10.0),
      child: new Text("顺序数据:$index",
        style: new TextStyle(fontSize: 14.0),
      ),
    );
  }

  int _itemCount;

  @override
  void initState() {
    Navigator.popUntil(context, (Route<dynamic> route){
      if(route.settings.name == ''){

      }
    });
    /*
    Navigator.of(context).push(new MaterialPageRoute(builder: (BuildContext context){

      return null;

    })).then((data){



    });*/



    _itemCount = 10;
    super.initState();
  }

  Future<Null> onFooterRefresh() {
    return new Future.delayed(new Duration(seconds: 2), () {
      setState(() {
        _itemCount += 10;
      });
    });
  }

  Future<Null> onHeaderRefresh() {
    return new Future.delayed(new Duration(seconds: 2), () {
      setState(() {
        _itemCount = 10;
      });
    });
  }

  @override
  Widget build(BuildContext context) {



    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new SafeArea(
            child: new Refresh(
          onFooterRefresh: onFooterRefresh,
          onHeaderRefresh: onHeaderRefresh,
          childBuilder: (BuildContext context,
              {ScrollController controller, ScrollPhysics physics}) {
            return new Container(
                child: new ListView.builder(
              physics: physics,
              controller: controller,
              itemBuilder: _itemBuilder,
              itemCount: _itemCount,
            ));
          },
        )));
  }
}
