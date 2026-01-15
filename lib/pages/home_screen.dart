import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:object_detection_app/app/app_resources.dart';
import 'package:object_detection_app/app/base/base_stateful.dart';
import 'package:object_detection_app/main.dart';
import 'package:object_detection_app/view_models/home_view_model.dart';
import 'package:object_detection_app/widgets/aperture/aperture_widget.dart';
import 'package:object_detection_app/widgets/aperture/confidence_widget.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.selectedLabel});

  final String selectedLabel;

  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends BaseStateful<HomeScreen, HomeViewModel>
    with WidgetsBindingObserver {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  late StreamController<Map> apertureController;

  @override
  bool get wantKeepAlive => true;

  @override
  void afterFirstBuild(BuildContext context) {
    super.afterFirstBuild(context);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
    apertureController = StreamController<Map>.broadcast();
  }

  void initCamera() {
    _cameraController = CameraController(
      cameras[viewModel.state.cameraIndex],
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _cameraController.initialize().then((_) {
      if (!mounted) return;

      viewModel.resetCollisionState();

      _cameraController.setFlashMode(FlashMode.off);

      setState(() {});

      _cameraController.startImageStream((image) async {
        if (!mounted) return;
        await viewModel.runModel(context, image);
      });
    });
  }

  void loadModel() async {
    await viewModel.loadModel();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    viewModel.close();
    _cameraController.dispose();
    apertureController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_cameraController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else {
      initCamera();
    }
  }

  @override
  Widget buildPageWidget(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Provider.of<NavigationService>(context, listen: false)
        //     .pushNamedAndRemoveUntil(
        //   AppRoute.chooseObjectScreen,
        // );

        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: buildAppBarWidget(context),
        body: buildBodyWidget(context),
      ),
    );
  }

  @override
  AppBar buildAppBarWidget(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      centerTitle: true,
      backgroundColor: AppColors.blue,
      title: Text(
        AppStrings.title,
        style: AppTextStyles.boldTextStyle(
            color: AppColors.white, fontSize: AppFontSizes.large),
      ),
    );
  }

  @override
  Widget buildBodyWidget(BuildContext context) {
    double heightAppBar = AppBar().preferredSize.height;

    bool isInitialized = _cameraController.value.isInitialized;

    final Size screen = MediaQuery.of(context).size;
    final double screenHeight = max(screen.height, screen.width);
    final double screenWidth = min(screen.height, screen.width);

    final Size previewSize = isInitialized
        ? _cameraController.value.previewSize!
        : const Size(100, 100);
    final double previewHeight = max(previewSize.height, previewSize.width);
    final double previewWidth = min(previewSize.height, previewSize.width);

    final double screenRatio = screenHeight / screenWidth;
    final double previewRatio = previewHeight / previewWidth;
    final maxHeight =
        screenRatio > previewRatio ? screenHeight : screenWidth * previewRatio;
    final maxWidth =
        screenRatio > previewRatio ? screenHeight / previewRatio : screenWidth;

    return Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        color: Colors.grey.shade900,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: <Widget>[
                  OverflowBox(
                    maxHeight: maxHeight,
                    maxWidth: maxWidth,
                    child: FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (_, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return CameraPreview(_cameraController);
                          } else {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.blue));
                          }
                        }),
                  ),
                  Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
                    return ConfidenceWidget(
                      heightAppBar: heightAppBar,
                      entities: homeViewModel.state.recognitions,
                      previewHeight: max(homeViewModel.state.heightImage,
                          homeViewModel.state.widthImage),
                      previewWidth: min(homeViewModel.state.heightImage,
                          homeViewModel.state.widthImage),
                      screenWidth: MediaQuery.of(context).size.width,
                      screenHeight: MediaQuery.of(context).size.height,
                      selectedObject: widget.selectedLabel,
                    );
                  }),
                  OverflowBox(
                    maxHeight: maxHeight,
                    maxWidth: maxWidth,
                    child: ApertureWidget(
                      apertureController: apertureController,
                    ),
                  ),
                ],
              )),
        ));
  }
}
