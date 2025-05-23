/// 睡眠时长图表绘制器
/// 根据传入的参数绘制睡眠时长图表，包括背景、网格线、标题、条形图和底部信息等
import 'package:flutter/material.dart';

class SleepDurationPainter extends CustomPainter {
  /// 高度单位，用于计算条形图的高度
  final double heightUnit;
  /// 标题区域的高度
  final double titleHeight;
  /// 标题与图表之间的间距
  final double titleGap;
  /// X轴标题的偏移量
  final double xAxisTitleOffset;
  /// 图表背景颜色
  final Color bgColor;
  /// 睡眠详情数据列表
  final List<SleepDetailChart> details;
  /// 开始时间
  final DateTime startTime;
  /// 结束时间
  final DateTime endTime;
  /// X轴标题的高度
  final double xAxisTitleHeight;
  /// 曲线边缘的高度，用于绘制连接处的圆角效果
  double curveEdgeHeight = 10.0;
  /// 指示器的水平位置
  double indicatorPosition;

  /// 水平网格线的样式
  final LineStyle horizontalLineStyle;
  /// 垂直网格线的样式
  final LineStyle verticalLineStyle;
  /// 水平网格线的数量
  final int horizontalLineCount;
  /// 网格线的画笔样式
  final PaintStyle dividerPaintStyle;
  /// 睡眠阶段之间的渐变连接线样式
  final List<SleepStageStyle> sleepStageStyles;
  /// 不同睡眠阶段对应的颜色映射
  final Map<SleepStage, Color> stageColors;

  /// 底部信息的文本样式
  final TextStyle bottomInfoTextStyle;
  /// 日期格式化函数
  final String Function(DateTime) dateFormatter;

  /// 默认的睡眠阶段颜色映射
  static final Map<SleepStage, Color> _defaultStageColors = {
    SleepStage.light: Color(0xFF4870F3), // 浅睡眠 - 浅蓝色
    SleepStage.deep: Color(0xFF21B2A1),  // 深睡眠 - 青色
    SleepStage.rem: Color(0xFFFCD166),   // 快速眼动 - 黄色
  };

  /// 默认的底部信息文本样式
  static const TextStyle _defaultBottomInfoTextStyle = TextStyle(
    color: Color(0xFF666666),
    fontSize: 10,
    height: 14.0/10.0,
  );

  /// 默认的日期格式化函数
  /// 格式：MM-DD HH:mm
  static String _defaultDateFormatter(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 图表实际高度
  double chartHeight = 0;
  /// 条形图的高度
  double barHeight = 0;
  /// 起始高度
  double startHeight = 0;

  /// 默认的睡眠阶段渐变连接线样式
  static final List<SleepStageStyle> _defaultSleepStageStyles = [
    SleepStageStyle(
      gradientColor: [Color(0xFF4870F3), Color(0xFF21B2A1)], // 深睡眠到浅睡眠的渐变
      value: SleepStageStyleValue.deepAndLight,
    ),
    SleepStageStyle(
      gradientColor: [Color(0xFFFCD166), Color(0xFF21B2A1)], // 深睡眠到快速眼动的渐变
      value: SleepStageStyleValue.deepAndRem,
    ),
    SleepStageStyle(
      gradientColor: [Color(0xFFFCD169), Color(0xFF4870F3)], // 浅睡眠到快速眼动的渐变
      value: SleepStageStyleValue.lightAndRem,
    ),
  ];

  SleepDurationPainter({
    required this.heightUnit,
    required this.titleHeight,
    required this.titleGap,
    required this.xAxisTitleOffset,
    required this.bgColor,
    required this.details,
    required this.startTime,
    required this.endTime,
    required this.xAxisTitleHeight,
    this.horizontalLineStyle = const LineStyle(width: 5.0, space: 3.0),
    this.verticalLineStyle = const LineStyle(width: 5.0, space: 3.0),
    this.horizontalLineCount = 8, // 默认8个间隔，9条线
    this.dividerPaintStyle = const PaintStyle(
      color: Color(0xFFEEEEEE),
      strokeWidth: 1.0,
      style: PaintingStyle.stroke,
      strokeCap: StrokeCap.round,
    ),
    List<SleepStageStyle>? sleepStageStyles,
    Map<SleepStage, Color>? stageColors,
    TextStyle? bottomInfoTextStyle,
    String Function(DateTime)? dateFormatter,
    this.indicatorPosition = 0.0, // 默认位置为0
  })  : this.sleepStageStyles = sleepStageStyles ?? _defaultSleepStageStyles,
        this.stageColors = stageColors ?? _defaultStageColors,
        this.bottomInfoTextStyle = bottomInfoTextStyle ?? _defaultBottomInfoTextStyle,
        this.dateFormatter = dateFormatter ?? _defaultDateFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    // 在paint方法中根据size计算实际值
    chartHeight = (size.height - titleHeight - titleGap - xAxisTitleOffset - xAxisTitleHeight);
    barHeight = chartHeight * heightUnit;
    startHeight = chartHeight * heightUnit;
    curveEdgeHeight = barHeight / 2 + 3;

    // 绘制背景
    _drawBackground(canvas, size);
    // 绘制线条
    _drawLines(canvas, size);
    // 绘制标题
    _drawTitle(canvas, size);
    //绘制指示条
    _drawIndicator(canvas, size);
    // 绘制条形图
    _drawBarArea(canvas, size);
    // 绘制底部信息
    _drawBottomInfo(canvas, size);
  }

  /// 绘制背景
  /// 在图表区域绘制纯色背景
  void _drawBackground(Canvas canvas, Size size) {
    final chartHeight = (size.height - titleHeight - titleGap - xAxisTitleOffset - xAxisTitleHeight);
    final backgroundPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, titleHeight + titleGap, size.width, chartHeight),
        backgroundPaint);
  }

  /// 绘制网格线
  /// 包括水平网格线和垂直网格线
  void _drawLines(Canvas canvas, Size size) {
    final dividerPaint = Paint()
      ..color = dividerPaintStyle.color
      ..strokeWidth = dividerPaintStyle.strokeWidth
      ..style = dividerPaintStyle.style
      ..strokeCap = dividerPaintStyle.strokeCap;

    _drawHorizontalLines(canvas, size, dividerPaint);
    _drawVerticalLines(canvas, size, dividerPaint);
  }

  /// 绘制水平网格线
  /// 根据horizontalLineCount参数绘制等间距的水平虚线
  void _drawHorizontalLines(Canvas canvas, Size size, Paint paint) {
    final lineSpacing = chartHeight / horizontalLineCount;

    for (int i = 0; i <= horizontalLineCount; i++) {
      final y = titleHeight + titleGap + (i * lineSpacing);
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + horizontalLineStyle.width, y),
          paint,
        );
        startX += horizontalLineStyle.width + horizontalLineStyle.space;
      }
    }
  }

  /// 绘制垂直网格线
  /// 在图表左右两侧绘制等间距的垂直虚线
  void _drawVerticalLines(Canvas canvas, Size size, Paint paint) {
    double startY = titleHeight + titleGap;
    final endY = titleHeight + titleGap + chartHeight;

    while (startY < endY) {
      // 左侧垂直线
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + verticalLineStyle.width),
        paint,
      );
      // 右侧垂直线
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + verticalLineStyle.width),
        paint,
      );
      startY += verticalLineStyle.width + verticalLineStyle.space;
    }
  }

  /// 绘制睡眠阶段条形图
  /// 根据details数据绘制不同睡眠阶段的条形，并添加连接效果。
  /// 注意：这里每个bar的left坐标累加方式（i==0时为0，之后每次加上前一个bar的width）
  /// 必须与_drawTitle中的区间判断保持完全一致，否则会导致指示器与bar的视觉区间不一致。
  void _drawBarArea(
    Canvas canvas,
    Size size,
  ) {
    double left = 0; // 当前bar的起始x坐标

    for (int i = 0; i < details.length; i++) {
      // 计算每个条形的起始位置
      // i==0时left=0，之后每次累加前一个bar的width
      i == 0 ? left = 0 : left += details[i - 1].width;
      print("left: $left");
      print("details[i].width: ${details[i].width}");

      final endY = startHeight * getHeightFromStage(details[i].model);
      final startY = endY + titleHeight + titleGap;

      // 创建条形图的画笔
      final paint = Paint()
        ..color = stageColors[details[i].model]!
        ..style = PaintingStyle.fill;

      // 绘制圆角矩形
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          startY,
          details[i].width,
          barHeight,
        ),
        Radius.circular(10),
      );

      canvas.drawRRect(rect, paint);

      // 绘制连接处的曲线边缘
      _drawCurveEdge(
        canvas: canvas,
        currentIndex: i,
        left: left,
      );

      // 绘制条形之间的连接线
      if (i > 0) {
        _drawConnectedLine(
          canvas: canvas,
          currentIndex: i,
          left: left,
        );
      }
    }
  }

  /// 绘制条形之间的连接线
  /// 使用渐变色绘制不同睡眠阶段之间的连接线
  void _drawConnectedLine({
    required Canvas canvas,
    required int currentIndex,
    required double left,
  }) {
    // var connectX = left;
    // 计算连接线的起始和结束位置
    final startY = titleHeight + titleGap +
        (getHeightFromStage(details[currentIndex - 1].model) *
            heightUnit *
            chartHeight);

    final endY = titleHeight + titleGap +
        (getHeightFromStage(details[currentIndex].model) *
            heightUnit *
            chartHeight);

    // 调整连接线的位置，确保正确的连接效果
    final actualStartY = startY > endY ? endY + barHeight : startY + barHeight;
    final actualEndY = startY > endY ? startY : endY;

    // 根据睡眠阶段选择对应的渐变样式
    final prevModel = details[currentIndex - 1].model;
    final currentModel = details[currentIndex].model;
    SleepStageStyle? style;

    // 根据不同的睡眠阶段组合选择对应的渐变样式
    if (prevModel == SleepStage.deep && currentModel == SleepStage.light) {
      style = sleepStageStyles[0]; // 深睡眠到浅睡眠
    } else if (prevModel == SleepStage.deep && currentModel == SleepStage.rem) {
      style = sleepStageStyles[1]; // 深睡眠到快速眼动
    } else if (prevModel == SleepStage.light && currentModel == SleepStage.rem) {
      style = sleepStageStyles[2]; // 浅睡眠到快速眼动
    } else if (prevModel == SleepStage.light && currentModel == SleepStage.deep) {
      style = sleepStageStyles[0]; // 浅睡眠到深睡眠
    } else if (prevModel == SleepStage.rem && currentModel == SleepStage.deep) {
      style = sleepStageStyles[1]; // 快速眼动到深睡眠
    } else if (prevModel == SleepStage.rem && currentModel == SleepStage.light) {
      style = sleepStageStyles[2]; // 快速眼动到浅睡眠
    }

    // 使用渐变色绘制连接线
    final gradientColors = style?.gradientColor;
    if (gradientColors != null && gradientColors.isNotEmpty) {
      final connectPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ).createShader(Rect.fromPoints(
          Offset(left , actualStartY),
          Offset(left  , actualEndY),
        ))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      Path connectPath = Path();
      connectPath.moveTo(left, actualStartY);
      connectPath.lineTo(left, actualEndY);

      canvas.drawPath(connectPath, connectPaint);
    }
  }

  /// 创建并绘制裁剪路径
  /// 用于绘制条形图连接处的圆角效果
  void _drawClippedCorner({
    required Canvas canvas,
    required double centerX,
    required double centerY,
    required double left,
    required SleepStage currentModel,
    required int currentIndex,
    required Corner corner,
  }) {
    // 创建填充画笔
    final clippedPaint = Paint()
      ..color = stageColors[currentModel]!
      ..style = PaintingStyle.fill;

    // 创建第一个裁剪路径
    final cornerPath = Path();
    cornerPath.moveTo(centerX, centerY);

    // 根据角落位置设置不同的路径
    switch (corner) {
      case Corner.topLeft:
        cornerPath.lineTo(centerX - 0.5, centerY - curveEdgeHeight);
        cornerPath.lineTo(centerX + details[currentIndex].width/2, centerY - curveEdgeHeight);
        cornerPath.lineTo(centerX + details[currentIndex].width/2, centerY);
        break;
      case Corner.bottomLeft:
        cornerPath.lineTo(centerX - 0.5, centerY + curveEdgeHeight);
        cornerPath.lineTo(centerX + details[currentIndex].width/2, centerY + curveEdgeHeight);
        cornerPath.lineTo(centerX + details[currentIndex].width/2, centerY);
        break;
      case Corner.topRight:
        cornerPath.lineTo(centerX + 0.5, centerY - curveEdgeHeight);
        cornerPath.lineTo(centerX - details[currentIndex].width/2, centerY - curveEdgeHeight);
        cornerPath.lineTo(centerX - details[currentIndex].width/2, centerY);
        break;
      case Corner.bottomRight:
        cornerPath.lineTo(centerX + 0.5, centerY + curveEdgeHeight);
        cornerPath.lineTo(centerX - details[currentIndex].width/2, centerY + curveEdgeHeight);
        cornerPath.lineTo(centerX - details[currentIndex].width/2, centerY);
        break;
    }
    cornerPath.close();
    // canvas.drawPath(cornerPath, clippedPaint);

    // 创建第二个裁剪路径
    final barRectPath = Path();
    switch (corner) {
      case Corner.topLeft:
      case Corner.topRight:
        barRectPath.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, centerY - barHeight,
                details[currentIndex].width, barHeight / 2),
            Radius.circular(10),
          ),
        );
        break;
      case Corner.bottomLeft:
      case Corner.bottomRight:
        barRectPath.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, centerY + barHeight / 2,
                details[currentIndex].width, barHeight / 2),
            Radius.circular(10),
          ),
        );
        break;
    }
    barRectPath.close();

    // 使用路径差集运算创建最终路径
    final clippedPath = Path.combine(PathOperation.difference, cornerPath, barRectPath);

    // 绘制最终路径
    canvas.drawPath(clippedPath, clippedPaint);
  }

  /// 绘制曲线边缘
  /// 在条形图的四个角添加圆角效果，用于连接不同睡眠阶段的条形
  void _drawCurveEdge({
    required Canvas canvas,
    required int currentIndex,
    required double left,
  }) {
    // 获取当前条形和上一个条形的睡眠阶段
    final currentModel = details[currentIndex].model;
    final prevModel = currentIndex > 0 ? details[currentIndex - 1].model : null;

    // 判断是否是第一个或最后一个条形
    final isFirst = currentIndex == 0;
    final isLast = currentIndex == details.length - 1;

    // 计算当前条形的位置
    final currentY = titleHeight + titleGap +
        (getHeightFromStage(currentModel) * heightUnit * chartHeight);

    var parameter = {
      'canvas': canvas,
      'currentModel': currentModel,
      'currentIndex': currentIndex,
      'left': left,
    };

    // 处理左上角和左下角（如果不是第一个条形）
    if (!isFirst) {
      final centerX = left;
      final centerY = currentY + (barHeight / 2);
      parameter['centerX'] = centerX;
      parameter['centerY'] = centerY;

      // 根据睡眠阶段选择角落位置
      if (currentModel == SleepStage.deep) {
        parameter['corner'] = Corner.topLeft;
      } else if (currentModel == SleepStage.light && prevModel == SleepStage.rem) {
        parameter['corner'] = Corner.topLeft;
      } else if (currentModel == SleepStage.rem) {
        parameter['corner'] = Corner.bottomLeft;
      } else if (currentModel == SleepStage.light && prevModel == SleepStage.deep) {
        parameter['corner'] = Corner.bottomLeft;
      }

      _drawClippedCorner(
        canvas: parameter['canvas'] as Canvas,
        centerX: parameter['centerX'] as double,
        centerY: parameter['centerY'] as double,
        left: parameter['left'] as double,
        currentModel: parameter['currentModel'] as SleepStage,
        currentIndex: parameter['currentIndex'] as int,
        corner: parameter['corner'] as Corner,
      );
    }

    // 处理右上角和右下角（如果不是最后一个条形）
    if (!isLast) {
      final nextModel = details[currentIndex + 1].model;

      // 计算中心点
      final centerX = left + details[currentIndex].width;
      final centerY = currentY + (barHeight / 2);
      parameter['centerX'] = centerX;
      parameter['centerY'] = centerY;

      // 根据睡眠阶段选择角落位置
      if (currentModel == SleepStage.deep) {
        parameter['corner'] = Corner.topRight;
      } else if (currentModel == SleepStage.rem) {
        parameter['corner'] = Corner.bottomRight;
      } else if (currentModel == SleepStage.light) {
        if (nextModel == SleepStage.rem) {
          parameter['corner'] = Corner.topRight;
        } else if (nextModel == SleepStage.deep) {
          parameter['corner'] = Corner.bottomRight;
        }
      }

      _drawClippedCorner(
        canvas: parameter['canvas'] as Canvas,
        centerX: parameter['centerX'] as double,
        centerY: parameter['centerY'] as double,
        left: parameter['left'] as double,
        currentModel: parameter['currentModel'] as SleepStage,
        currentIndex: parameter['currentIndex'] as int,
        corner: parameter['corner'] as Corner,
      );
    }
  }

  /// 绘制标题区域
  /// 包括睡眠阶段名称、时长和时间范围。
  /// 注意：bar 区间的累加方式必须与 _drawBarArea 完全一致，
  /// 即currentX的累加方式和_drawBarArea的left保持一致，
  /// 否则指示器与bar的视觉区间会出现偏差。
  void _drawTitle(Canvas canvas, Size size) {
    // 打印当前指示器位置，便于调试
    // ignore: avoid_print

    double currentX = 0; // 当前bar的起始x坐标
    SleepDetailChart? currentStage;
    double stageStartX = 0;

    for (int i = 0; i < details.length; i++) {
      final detail = details[i];
      final barLeft = currentX;
      final barRight = currentX + detail.width;

      // 最后一个bar用右闭区间，其余用左闭右开区间
      bool inBar = (i < details.length - 1)
          ? (indicatorPosition >= barLeft && indicatorPosition < barRight)
          : (indicatorPosition >= barLeft && indicatorPosition <= barRight);
      if (inBar) {
        currentStage = detail;
        stageStartX = currentX;
        // 不break，确保最后一个bar也能被正确命中
      }
      // 这里的累加方式必须和 _drawBarArea 保持一致
      currentX = barRight;
    }

    // 如果没有找到对应的阶段，直接返回不显示标题
    if (currentStage == null) {
      return;
    }

    // 只在指示器严格落在bar物理范围内时才显示标题
    double barLeft = stageStartX;
    double barRight = stageStartX + currentStage.width;
    if (indicatorPosition < barLeft || indicatorPosition > barRight) {
      return;
    }

    // 创建文本样式
    final textTitleStyle = TextStyle(
      color: Color(0xFF1B6BFF),
      fontSize: 16,
    );
    final textTitleMinuteStyle = TextStyle(
      color: Color(0xFF1B6BFF),
      fontSize: 20,
      fontWeight: FontWeight.w600,
    );
    final textSubTitleStyle = TextStyle(
      color: Color(0xFF999999),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    // 根据睡眠阶段设置标题文本
    String stageName;
    switch (currentStage.model) {
      case SleepStage.light:
        stageName = 'Light';
        break;
      case SleepStage.deep:
        stageName = 'Deep';
        break;
      case SleepStage.rem:
        stageName = 'REM';
        break;
      default:
        stageName = 'Unknown';
    }

    // 格式化时间
    String formatTime(DateTime time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    // 创建主标题文本画笔
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: stageName,
            style: textTitleStyle,
          ),
          TextSpan(
            text: currentStage.duration.toString(),
            style: textTitleMinuteStyle,
          ),
          TextSpan(
            text: 'min',
            style: textTitleStyle,
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );

    // 创建时间范围文本画笔
    final timeRangePainter = TextPainter(
      text: TextSpan(
        text: '${formatTime(currentStage.startTime)} ~ ${formatTime(currentStage.endTime)}',
        style: textSubTitleStyle,
      ),
      textDirection: TextDirection.ltr,
    );

    // 布局文本
    textPainter.layout();
    timeRangePainter.layout();

    // 计算背景矩形位置
    final bgWidth = 129.0;
    final bgHeight = 45.0;
    
    // 计算标题位置，使用当前阶段的中心点
    double bgX = stageStartX + (currentStage.width / 2) - (bgWidth / 2);
    
    // 限制标题不超出边界
    if (bgX < 0) {
      bgX = 0;
    } else if (bgX + bgWidth > size.width) {
      bgX = size.width - bgWidth;
    }
    
    final bgY = (titleHeight - bgHeight) / 2;

    // 绘制半透明背景
    final bgPaint = Paint()
      ..color = Color.fromRGBO(28, 107, 255, 0.03)
      ..style = PaintingStyle.fill;
    
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bgX, bgY, bgWidth, bgHeight),
      Radius.circular(8),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 绘制主标题
    final x = bgX + (bgWidth - textPainter.width) / 2;
    final y = bgY + 2;
    textPainter.paint(canvas, Offset(x, y));

    // 绘制时间范围
    final timeX = bgX + (bgWidth - timeRangePainter.width) / 2;
    final timeY = bgY + bgHeight - timeRangePainter.height - 2;
    timeRangePainter.paint(canvas, Offset(timeX, timeY));
  }

  /// 绘制指示器
  /// 在图表中央绘制垂直指示线和底部指示器
  void _drawIndicator(Canvas canvas, Size size) {
    final chartHeight = size.height - titleHeight - titleGap - xAxisTitleOffset - xAxisTitleHeight;
    
    // 创建指示线画笔
    final indicatorPaint = Paint()
      ..color = Color(0xFFDADADA)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 使用传入的指示器位置
    final centerX = indicatorPosition;
    final startY = titleHeight + titleGap;
    final endY = startY + chartHeight;

    canvas.drawLine(
      Offset(centerX, startY - titleGap - 1),
      Offset(centerX, endY),
      indicatorPaint,
    );

    // 创建底部指示器画笔
    final bottomRectPaint = Paint()
      ..color = Color(0xFFF6F6F6)
      ..style = PaintingStyle.fill;

    final bottomBorderPaint = Paint()
      ..color = Color(0xFFDADADA)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 绘制底部指示器
    final rectWidth = 18.0;
    final rectHeight = 9.0;
    final rectX = centerX - rectWidth / 2;
    final rectY = endY - rectHeight;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rectX, rectY + rectHeight / 2, rectWidth, rectHeight),
      Radius.circular(6),
    );

    canvas.drawRRect(rect, bottomRectPaint);
    canvas.drawRRect(rect, bottomBorderPaint);
  }

  /// 绘制底部信息
  /// 显示开始时间和结束时间
  void _drawBottomInfo(Canvas canvas, Size size) {
    // 格式化日期
    final startDateStr = dateFormatter(startTime);
    final endDateStr = dateFormatter(endTime);

    // 创建日期文本画笔
    final startDatePainter = TextPainter(
      text: TextSpan(
        text: startDateStr,
        style: bottomInfoTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );

    final endDatePainter = TextPainter(
      text: TextSpan(
        text: endDateStr,
        style: bottomInfoTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );

    // 布局文本
    startDatePainter.layout();
    endDatePainter.layout();

    // 绘制日期文本
    final bottomY = size.height - xAxisTitleOffset - xAxisTitleHeight + 5;
    startDatePainter.paint(canvas, Offset(0, bottomY));
    endDatePainter.paint(canvas, Offset(size.width - endDatePainter.width, bottomY));
  }

  @override
  bool shouldRepaint(SleepDurationPainter oldDelegate) {
    return oldDelegate.indicatorPosition != indicatorPosition;
  }
}

/// 线条样式类
/// 定义网格线的宽度和间距
class LineStyle {
  /// 线条宽度
  final double width;
  /// 线条间距
  final double space;

  const LineStyle({
    required this.width,
    required this.space,
  });
}

/// 画笔样式类
/// 定义画笔的颜色、宽度、样式和端点形状
class PaintStyle {
  /// 画笔颜色
  final Color color;
  /// 线条宽度
  final double strokeWidth;
  /// 绘制样式
  final PaintingStyle style;
  /// 线条端点形状
  final StrokeCap strokeCap;

  const PaintStyle({
    required this.color,
    required this.strokeWidth,
    required this.style,
    required this.strokeCap,
  });
}

/// 角落位置枚举
/// 用于定义条形图连接处的四个角落位置
enum Corner {
  /// 左上角
  topLeft,
  /// 左下角
  bottomLeft,
  /// 右上角
  topRight,
  /// 右下角
  bottomRight,
}

/// 睡眠详情数据类
/// 用于存储单个睡眠阶段的基本信息
class SleepDetail {
  final SleepStage stage; // 睡眠阶段类型
  final DateTime time; // 阶段发生时间

  SleepDetail({
    required this.stage,
    required this.time,
  });
}

/// 睡眠详情图表数据类
/// 用于存储图表绘制所需的睡眠阶段详细信息
class SleepDetailChart {
  final SleepStage model; // 睡眠阶段类型
  final double width; // 阶段在图表中的宽度
  final DateTime startTime; // 阶段开始时间
  final DateTime endTime; // 阶段结束时间
  final int duration; // 持续时间（分钟）

  SleepDetailChart({
    required this.model,
    required this.width,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  /// 创建测试用的睡眠详情图表数据
  factory SleepDetailChart.withTest() {
    return SleepDetailChart(
      model: SleepStage.light,
      width: 100,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(minutes: 30)),
      duration: 30,
    );
  }
}

/// 睡眠阶段枚举
/// 与原生端mode严格对应，用于标识不同的睡眠状态
enum SleepStage {
  light, // 浅睡 (mode=1)
  deep, // 深睡 (mode=2)
  awake, // 清醒 (mode=3)
  notWorn, // 未佩戴 (mode=4)
  rem, // 快速眼动 (mode=5)
  unknown, // 其他未知状态
}

/// 从睡眠阶段枚举获取对应的mode值
/// 用于日志显示和与原生端通信
int getModeFromStage(SleepStage stage) {
  switch (stage) {
    case SleepStage.light:
      return 1;
    case SleepStage.deep:
      return 2;
    case SleepStage.awake:
      return 3;
    case SleepStage.notWorn:
      return 4;
    case SleepStage.rem:
      return 5;
    case SleepStage.unknown:
      return -1;
  }
}

/// 获取睡眠阶段在图表中的高度值
/// 用于确定不同睡眠阶段在图表中的显示高度
int getHeightFromStage(SleepStage stage) {
  switch (stage) {
    case SleepStage.light:
      return 4;
    case SleepStage.deep:
      return 6;
    case SleepStage.rem:
      return 2;
    default:
      return 7;
  }
}

/// 创建睡眠时长图表数据
/// 根据原始睡眠详情数据计算每个阶段在图表中的宽度和持续时间
/// @param parentWidth 父容器宽度
/// @param details 原始睡眠详情数据列表
/// @param totalDuration 总睡眠时长（分钟）
/// @return 处理后的睡眠详情图表数据列表
List<SleepDetailChart> createSleepDurationData({
  required double parentWidth,
  required List<SleepDetail> details,
  required int totalDuration,
}) {
  if (details.isEmpty) return [];

  List<SleepDetailChart> result = [];
  
  for (int i = 0; i < details.length; i++) {
    final currentDetail = details[i];
    final nextDetail = i < details.length - 1 ? details[i + 1] : null;
    
    // 计算当前阶段持续时间（分钟）
    final durationMinutes = nextDetail != null 
        ? nextDetail.time.difference(currentDetail.time).inMinutes
        : 0;
    
    // 计算百分比
    final percentage = durationMinutes / totalDuration;
    
    // 计算宽度
    final width = parentWidth * percentage;
    
    // 创建SleepDetailChart
    result.add(SleepDetailChart(
      model: currentDetail.stage,
      width: width,
      startTime: currentDetail.time,
      endTime: nextDetail?.time ?? currentDetail.time.add(Duration(minutes: durationMinutes)),
      duration: durationMinutes,
    ));
  }
  
  return result;
}

/// 睡眠阶段样式值枚举
/// 用于定义不同睡眠阶段之间的过渡样式
enum SleepStageStyleValue {
  deepAndLight, // Deep <=> Light (mode=1)
  deepAndRem, //  Deep <=> REM (mode=2)
  lightAndRem, // Light <=> REM (mode=3)
}

/// 睡眠阶段样式类
/// 用于定义睡眠阶段在图表中的显示样式
class SleepStageStyle {
  final List<Color>? gradientColor; // 渐变色列表
  final Color? color; // 纯色
  final SleepStageStyleValue value; // 样式值

  SleepStageStyle({
    this.gradientColor,
    this.color,
    required this.value,
  }) : assert(
    (gradientColor != null && color == null) || 
    (gradientColor == null && color != null),
    '必须提供gradientColor或color其中之一，但不能同时提供两者'
  );
}

/// 睡眠时长图表组件
/// 用于显示睡眠时长和各个阶段的详细信息
class SleepDurationChartWidget extends StatefulWidget {
  final List<SleepDetailChart> details; // 睡眠详情数据
  final DateTime startTime; // 开始时间
  final DateTime endTime; // 结束时间
  final double heightUnit; // 高度单位
  final double titleHeight; // 标题高度
  final double titleGap; // 标题间距
  final double xAxisTitleOffset; // X轴标题偏移
  final double xAxisTitleHeight; // X轴标题高度
  final Color bgColor; // 背景颜色
  final LineStyle horizontalLineStyle; // 水平线样式
  final LineStyle verticalLineStyle; // 垂直线样式
  final int horizontalLineCount; // 水平线数量
  final PaintStyle dividerPaintStyle; // 分隔线样式
  final List<SleepStageStyle>? sleepStageStyles; // 睡眠阶段样式
  final Map<SleepStage, Color>? stageColors; // 阶段颜色映射
  final TextStyle? bottomInfoTextStyle; // 底部信息文本样式
  final String Function(DateTime)? dateFormatter; // 日期格式化函数

  const SleepDurationChartWidget({
    Key? key,
    required this.details,
    required this.startTime,
    required this.endTime,
    required this.heightUnit,
    required this.titleHeight,
    required this.titleGap,
    required this.xAxisTitleOffset,
    required this.xAxisTitleHeight,
    required this.bgColor,
    this.horizontalLineStyle = const LineStyle(width: 5.0, space: 3.0),
    this.verticalLineStyle = const LineStyle(width: 5.0, space: 3.0),
    this.horizontalLineCount = 8,
    this.dividerPaintStyle = const PaintStyle(
      color: Color(0xFFEEEEEE),
      strokeWidth: 1.0,
      style: PaintingStyle.stroke,
      strokeCap: StrokeCap.round,
    ),
    this.sleepStageStyles,
    this.stageColors,
    this.bottomInfoTextStyle,
    this.dateFormatter,
  }) : super(key: key);

  @override
  State<SleepDurationChartWidget> createState() => _SleepDurationChartWidgetState();
}

/// 睡眠时长图表组件状态类
/// 管理图表的交互状态和指示器位置
class _SleepDurationChartWidgetState extends State<SleepDurationChartWidget> {
  double _indicatorPosition = 0.0; // 指示器位置
  bool _isFirstInit = true; // 是否首次初始化

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 首次初始化时设置指示器位置为中间
        if (_isFirstInit) {
          _indicatorPosition = constraints.maxWidth / 2;
          _isFirstInit = false;
        }

        return GestureDetector(
          // 开始水平拖动
          onHorizontalDragStart: (details) {
          },
          // 水平拖动更新
          onHorizontalDragUpdate: (details) {
            setState(() {
              _indicatorPosition = (_indicatorPosition + details.delta.dx)
                  .clamp(0.0, constraints.maxWidth);
            });
          },
          // 结束水平拖动
          onHorizontalDragEnd: (details) {
          },
          child: CustomPaint(
            painter: SleepDurationPainter(
              heightUnit: widget.heightUnit,
              titleHeight: widget.titleHeight,
              titleGap: widget.titleGap,
              xAxisTitleOffset: widget.xAxisTitleOffset,
              xAxisTitleHeight: widget.xAxisTitleHeight,
              bgColor: widget.bgColor,
              details: widget.details,
              startTime: widget.startTime,
              endTime: widget.endTime,
              horizontalLineStyle: widget.horizontalLineStyle,
              verticalLineStyle: widget.verticalLineStyle,
              horizontalLineCount: widget.horizontalLineCount,
              dividerPaintStyle: widget.dividerPaintStyle,
              sleepStageStyles: widget.sleepStageStyles,
              stageColors: widget.stageColors,
              bottomInfoTextStyle: widget.bottomInfoTextStyle,
              dateFormatter: widget.dateFormatter,
              indicatorPosition: _indicatorPosition,
            ),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }
} 
