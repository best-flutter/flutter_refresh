import 'package:flutter/widgets.dart';

import 'package:flutter_refresh/flutter_refresh.dart';

typedef Widget IndexedDataBuilder(BuildContext context,
    {dynamic item, int index, dynamic extraData});

typedef Widget HeaderFooterBuilder(BuildContext context,
    {List<dynamic> data, dynamic extraData});

class FlatList extends StatelessWidget {
  final HeaderFooterBuilder headerBuilder;
  final HeaderFooterBuilder footerBuilder;
  final IndexedDataBuilder itemBuilder;
  final List<dynamic> data;
  final dynamic extraData;

  //Grid View
  final int numColumns = 0;

  /**
   *
   */
  @override
  Widget build(BuildContext context) {
    int itemCount = data.length;
    int offset = 0;

    if (headerBuilder != null) {
      offset++;
      ++itemCount;
    }

    if (footerBuilder != null) {
      ++itemCount;
    }

    BoxScrollView scrollView;

    if (numColumns > 0) {
      return new GridView.count(
        crossAxisCount: numColumns,
      );
    }

    return new ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          if (headerBuilder != null) {
            return headerBuilder(context, data: data, extraData: extraData);
          }
        }

        if (index == itemCount - 1) {
          if (footerBuilder != null) {
            return footerBuilder(context, data: data, extraData: extraData);
            ;
          }
        }

        return itemBuilder(context,
            index: index,
            item: this.data[index + offset],
            extraData: extraData);
      },
      itemCount: itemCount,
    );
  }
}
