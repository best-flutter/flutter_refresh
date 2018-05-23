# flutter_refresh
A Flutter plugin for refreshing every scrollable view by pulling down-up.



# Show cases


![](https://github.com/jzoom/flutter_refresh/raw/master/example/res/1.gif)


# Roadmap

>>see:[ROADMAP.md](https://github.com/jzoom/flutter_refresh/blob/master/ROADMAP.md)

# Changelogs

>>see:[CHANGELOG.md](https://github.com/jzoom/flutter_refresh/blob/master/README.md)

# Quick Start


## Installation


1 Add 

```bash

flutter_refresh : ^0.0.1

```
to your pubspec.yaml ,and run 

```bash
flutter packages get 
```
in your project's root directory.




2 Add 

```

import 'package:flutter_refresh/flutter_refresh.dart';

```

and write the code like this:

```


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
    ...
    return new Refresh(
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
        );
  }



```

>> full example see here: [main.dart](https://github.com/jzoom/flutter_refresh/blob/master/example/lib/main.dart).








