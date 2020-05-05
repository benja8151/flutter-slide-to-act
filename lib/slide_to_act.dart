library flutterslidetoact;

import 'dart:math';

import 'package:flutter/material.dart';

/// Slider call to action component
class SlideAction extends StatefulWidget {
  /// The size of the sliding icon
  final double sliderButtonIconSize;

  /// Tha padding of the sliding icon
  final double sliderButtonIconPadding;

  /// The offset on the y axis of the slider icon
  final double sliderButtonYOffset;

  /// The child that is rendered instead of the default Text widget
  final Widget child;

  /// The height of the component
  final double height;

  /// The color of the inner circular button, of the tick icon of the text.
  /// If not set, this attribute defaults to primaryIconTheme.
  final Color innerColor;

  /// The color of the external area and of the arrow icon.
  /// If not set, this attribute defaults to accentColor from your theme.
  final Color outerColor;

  /// The text showed in the default Text widget
  final String text;

  /// The borderRadius of the sliding icon and of the background
  final double borderRadius;

  /// Callback called on submit
  /// If this is null the component will not animate to complete
  final VoidCallback onSubmit;

  /// Elevation of the component
  final double elevation;

  /// The widget to render instead of the default icon
  final Widget sliderButtonIcon;

  /// The widget to render instead of the default submitted icon
  final Widget submittedIcon;

  /// The duration of the animations
  final Duration animationDuration;

  /// If true the widget will be reversed
  final bool reversed;

  /// the alignment of the widget once it's submitted
  final Alignment alignment;

  /// Create a new instance of the widget
  const SlideAction({
    Key key,
    this.sliderButtonIconSize = 24,
    this.sliderButtonIconPadding = 16,
    this.sliderButtonYOffset = 0,
    this.height = 70,
    this.outerColor,
    this.borderRadius = 52,
    this.elevation = 6,
    this.animationDuration = const Duration(milliseconds: 300),
    this.reversed = false,
    this.alignment = Alignment.center,
    this.submittedIcon,
    this.onSubmit,
    this.child,
    this.innerColor,
    this.text,
    this.sliderButtonIcon,
  }) : super(key: key);
  @override
  SlideActionState createState() => SlideActionState();
}

/// Use a GlobalKey to access the state. This is the only way to call [SlideActionState.reset]
class SlideActionState extends State<SlideAction>
    with TickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();
  final GlobalKey _sliderKey = GlobalKey();
  double _dx = 0;
  double _maxDx = 0;
  double get _progress => _dx == 0 ? 0 : _dx / _maxDx;
  double _endDx = 0;
  double _dz = 1;
  double _initialContainerWidth, _containerWidth;
  double _checkAnimationDx = 0;
  bool submitted = false;
  AnimationController _checkAnimationController,
      _shrinkAnimationController,
      _resizeAnimationController,
      _cancelAnimationController;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(widget.reversed ? pi : 0),
        child: Container(
          key: _containerKey,
          height: widget.height,
          width: _containerWidth,
          constraints: _containerWidth != null
              ? null
              : BoxConstraints.expand(height: widget.height),
          child: Material(
            elevation: widget.elevation,
            color: widget.outerColor ?? Theme.of(context).accentColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: submitted
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(widget.reversed ? pi : 0),
                    child: Center(
                      child: Stack(
                        overflow: Overflow.clip,
                        children: <Widget>[
                          widget.submittedIcon ??
                              Icon(
                                Icons.done,
                                color: widget.innerColor ??
                                    Theme.of(context).primaryIconTheme.color,
                              ),
                          Positioned.fill(
                            right: 0,
                            child: Transform(
                              transform: Matrix4.rotationY(
                                  _checkAnimationDx * (pi / 2)),
                              alignment: Alignment.centerRight,
                              child: Container(
                                color: widget.outerColor ??
                                    Theme.of(context).accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    overflow: Overflow.visible,
                    children: <Widget>[
                      Opacity(
                        opacity: 1 - 1 * _progress,
                        child: Transform(
                          alignment: Alignment.center,
                          transform:
                              Matrix4.rotationY(widget.reversed ? pi : 0),
                          child: widget.child ??
                              Text(
                                widget.text ?? 'Slide to act',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.innerColor ??
                                      Theme.of(context).primaryIconTheme.color,
                                  fontSize: 24,
                                ),
                              ),
                        ),
                      ),
                      Positioned(
                        left: widget.sliderButtonYOffset,
                        child: Transform.scale(
                          scale: _dz,
                          origin: Offset(_dx, 0),
                          child: Transform.translate(
                            offset: Offset(_dx, 0),
                            child: Container(
                              key: _sliderKey,
                              child: GestureDetector(
                                onHorizontalDragUpdate: onHorizontalDragUpdate,
                                onHorizontalDragEnd: (details) async {
                                  _endDx = _dx;
                                  if (_progress <= 0.8 ||
                                      widget.onSubmit == null) {
                                    _cancelAnimation();
                                  } else {
                                    await _resizeAnimation();

                                    await _shrinkAnimation();

                                    await _checkAnimation();

                                    widget.onSubmit();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Material(
                                    borderRadius: BorderRadius.circular(
                                        widget.borderRadius),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                          widget.sliderButtonIconPadding),
                                      child: Transform.rotate(
                                        angle: -pi * _progress,
                                        child: Center(
                                          child: widget.sliderButtonIcon ??
                                              Icon(
                                                Icons.arrow_forward,
                                                size:
                                                    widget.sliderButtonIconSize,
                                                color: widget.outerColor ??
                                                    Theme.of(context)
                                                        .accentColor,
                                              ),
                                        ),
                                      ),
                                    ),
                                    color: widget.innerColor ??
                                        Theme.of(context)
                                            .primaryIconTheme
                                            .color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dx = (_dx + details.delta.dx).clamp(0.0, _maxDx);
    });
  }

  /// Call this method to revert the animations
  Future reset() async {
    await _checkAnimationController.reverse().orCancel;

    submitted = false;

    await _shrinkAnimationController.reverse().orCancel;

    await _resizeAnimationController.reverse().orCancel;

    await _cancelAnimation();
  }

  Future _checkAnimation() async {
    _checkAnimationController.reset();

    Tween(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _checkAnimationController,
      curve: Curves.slowMiddle,
    )..addListener(() {
        if (mounted) {
          setState(() {
            _checkAnimationDx = _checkAnimationController.value;
          });
        }
      }));
    await _checkAnimationController.forward().orCancel;
  }

  Future _shrinkAnimation() async {
    _shrinkAnimationController.reset();

    final diff = _initialContainerWidth - widget.height;
    Tween(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shrinkAnimationController,
      curve: Curves.elasticIn,
    )..addListener(() {
        if (mounted) {
          setState(() {
            _containerWidth = _initialContainerWidth -
                (diff * _shrinkAnimationController.value);
          });
        }
      }));

    setState(() {
      submitted = true;
    });
    await _shrinkAnimationController.forward().orCancel;
  }

  Future _resizeAnimation() async {
    _resizeAnimationController.reset();

    Tween(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _resizeAnimationController,
      curve: Curves.elasticIn,
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dz = 1 - _resizeAnimationController.value;
          });
        }
      }));
    await _resizeAnimationController.forward().orCancel;
  }

  Future _cancelAnimation() async {
    _cancelAnimationController.reset();
    Tween(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cancelAnimationController,
      curve: Curves.slowMiddle,
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dx = (_endDx - (_endDx * _cancelAnimationController.value));
          });
        }
      }));
    _cancelAnimationController.forward().orCancel;
  }

  @override
  void initState() {
    super.initState();

    _cancelAnimationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _checkAnimationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _shrinkAnimationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _resizeAnimationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox containerBox =
          _containerKey.currentContext.findRenderObject();
      _containerWidth = containerBox.size.width;
      _initialContainerWidth = _containerWidth;

      final RenderBox sliderBox = _sliderKey.currentContext.findRenderObject();
      final sliderWidth = sliderBox.size.width;

      _maxDx =
          _containerWidth - (sliderWidth / 2) - 40 - widget.sliderButtonYOffset;
    });
  }

  @override
  void dispose() {
    _cancelAnimationController.dispose();
    _checkAnimationController.dispose();
    _shrinkAnimationController.dispose();
    _resizeAnimationController.dispose();
    super.dispose();
  }
}