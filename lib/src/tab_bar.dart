import 'package:flutter/material.dart';
import './curve_painter.dart';
import './tab_item.dart';
import './tab_item_icon.dart';

/// Main Widget should be used in bottomNavBar
/// Must be wrapped with Default Tab controller or provide a tab controller
///
class JumpingTabBar extends StatefulWidget {
  final void Function(int index)? onChangeTab;
  final int selectedIndex;
  final TabController? controller;
  final Duration duration;
  final Color? backgroundColor;

  final List<TabItemIcon> items;

  final Gradient circleGradient;
  JumpingTabBar({
    Key? key,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 700),
    this.circleGradient = const LinearGradient(
      colors: [
        const Color(0xff630141),
        const Color(0xffB83F7D),
      ],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ),
    this.selectedIndex = 1,
    required this.items,
    this.controller,
    this.onChangeTab,
  }) : super(key: key);

  @override
  _JumpingTabBarState createState() => _JumpingTabBarState();
}

class _JumpingTabBarState extends State<JumpingTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  int selectedIndex = 1;
  double? itemWidth;
  late Animation<double> posAnim;
  late Animation<double> paintAnim;
  TabController? tabController;

  var pivotPoints = List.filled(4, Offset(0, 0));

  double circleSize = 50;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    itemWidth = MediaQuery.of(context).size.width / widget.items.length;
    final _newController = DefaultTabController.of(context);
    if (_newController != tabController) {
      tabController?.removeListener(onTabCtrlChange);
      tabController = _newController;
      tabController!.addListener(onTabCtrlChange);
    }
    Future.delayed(Duration(seconds: 1), () {
      onChangeTab(widget.selectedIndex, shouldCallParent: false);
    });
  }

  void onTabCtrlChange() {
    if (tabController!.index + 1 != selectedIndex)
      onChangeTab(tabController!.index + 1, shouldCallParent: false);
  }

  @override
  void dispose() {
    tabController!.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(JumpingTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      animationController.duration = widget.duration;
    }
    if (widget.selectedIndex != selectedIndex) {
      onChangeTab(widget.selectedIndex, shouldCallParent: false);
    }
  }

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    posAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      curve: ElasticOutCurve(.99),
      parent: animationController,
    ));
    paintAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      curve: Interval(.2, .8, curve: ElasticOutCurve(.99)),
      parent: animationController,
    ));
  }

  void onChangeTab(int index, {bool shouldCallParent = true}) {
    setState(() {
      selectedIndex = index;
    });
    if (tabController != null) tabController!.index = index - 1;
    if (widget.onChangeTab != null && shouldCallParent)
      widget.onChangeTab!(index);

    double cPoint = (itemWidth! - circleSize) / 2;
    var nextPx = (index - 1) * itemWidth! + cPoint;
    double nextPy = -15;
    double pivotx = pivotPoints[3].dx;
    double pivoty = -100;

    pivotPoints[0] = pivotPoints[3];
    animationController.reset();

    pivotPoints[1] = Offset(pivotx, pivoty);
    pivotPoints[2] = Offset(nextPx, pivoty);
    pivotPoints[3] = Offset(nextPx, nextPy);
    animationController.forward();
  }

  Offset getQuadraticBezier(double t) => getQuadraticBezier2(
        pivotPoints,
        t,
        0,
        pivotPoints.length - 1,
      );

  Offset getQuadraticBezier2(List<Offset> offsetList, double t, int i, int j) {
    if (i == j) return offsetList[i];

    Offset b0 = getQuadraticBezier2(offsetList, t, i, j - 1);
    Offset b1 = getQuadraticBezier2(offsetList, t, i + 1, j);
    return Offset((1 - t) * b0.dx + t * b1.dx, (1 - t) * b0.dy + t * b1.dy);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 75,
          color: widget.backgroundColor,
        ),
        SizedBox(
          height: 75,
          child: AnimatedBuilder(
            animation: animationController,
            builder: (_, child) => CustomPaint(
              painter: TabCurvePainter(
                itemSize: itemWidth,
                color: widget.items[selectedIndex - 1].curveColor,
                animValue: paintAnim.value,
                selectedIndex: selectedIndex,
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: animationController,
          child: Container(
            height: circleSize,
            width: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.circleGradient,
            ),
          ),
          builder: (_, child) {
            return Transform.translate(
              offset: getQuadraticBezier(posAnim.value),
              child: child,
            );
          },
        ),
        SizedBox(
          height: 75,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              widget.items.length,
              (index) => getTabItem(index),
            ),
          ),
        ),
      ],
    );
  }

  Widget getTabItem(int index) {
    var currentIndex = index + 1;
    var isSelected = currentIndex == selectedIndex;
    return TabItem(
      duration: widget.duration,
      tabItemIcon: widget.items[index],
      isSelected: isSelected,
      index: currentIndex,
      onTabChange: onChangeTab,
    );
  }
}
