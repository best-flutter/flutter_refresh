# flutter_refresh
A Flutter plugin for refreshing every scrollable view by pulling down-up.



# Show cases


# Installation


Add 

```bash

flutter_refresh : ^0.0.4

```
to your pubspec.yaml ,and run 

```bash
flutter packages get 
```
in your project's root directory.


# Roadmap

>>see:

# Quick Start

Add 
```


```

and write the code like this:

```
new Refresh(
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
        )


```








