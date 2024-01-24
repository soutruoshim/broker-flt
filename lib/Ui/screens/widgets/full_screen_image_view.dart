import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/AppIcon.dart';
import '../../../utils/Extensions/extensions.dart';
import '../../../utils/ui_utils.dart';

class FullScreenImageView extends StatefulWidget {
  final ImageProvider provider;
  const FullScreenImageView({
    super.key,
    required this.provider,
  });

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: AnnotatedRegion(
        value: SystemUiOverlayStyle(
            systemNavigationBarDividerColor: Colors.transparent,
            statusBarColor: Colors.black.withOpacity(0)),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: context.color.teritoryColor),
          ),
          backgroundColor: const Color.fromARGB(17, 0, 0, 0),
          body: InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1 / 1,
                child: GestureDetector(
                  onTap: () {},
                  child: Image(
                    image: widget.provider,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                              color:
                                  context.color.teritoryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10)),
                          child: UiUtils.getSvg(AppIcons.placeHolder,
                              color: context.color.teritoryColor));
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;

                      return FittedBox(
                        fit: BoxFit.none,
                        child: SizedBox(
                            width: 50, height: 50, child: UiUtils.progress()),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
