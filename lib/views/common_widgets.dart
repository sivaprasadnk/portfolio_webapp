import 'package:animate_do/animate_do.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:spnk/utils/common_colors.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class GooglePlayButton extends StatelessWidget {
  final String url;
  const GooglePlayButton({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await launchUrl(Uri.parse(url));
        // launch(url);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: kGreyColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
              child: Image.asset(
                'assets/images/google-play.png',
                height: 40,
                // width: 10,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3) +
                  const EdgeInsets.only(right: 13),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GET IT ON',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontWeight: FontWeight.w200,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Google Play',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WinddowsGooglePlayButton extends StatelessWidget {
  final double screenWidth;
  final String url;
  const WinddowsGooglePlayButton({
    required this.screenWidth,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // launch(url);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: kGreyColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset(
                'assets/images/google-play.png',
                height: 35,
                // width: 10,
              ),
            ),
            const SizedBox(
              width: 1,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GET IT ON',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: Text(
                      'Google Play',
                      style: TextStyle(
                        color: kWhiteColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleText extends StatelessWidget {
  final String title;
  const TitleText({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 30),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: kRajdhaniFontFamily,
          fontWeight: FontWeight.bold,
          color: kWhiteColor,
          fontSize: 20,
        ),
      ),
    );
  }
}

// class ProPicMediumWithBlob extends StatelessWidget {
//   final double width;
//   const ProPicMediumWithBlob({
//     required this.width,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedOpacity(
//       duration: const Duration(milliseconds: 900),
//       opacity: 1,
//       child: Image.asset(
//         'assets/images/picWithBlob.png',
//         width: width,
//       ),
//     );
//   }
// }

class WindowsRightFooter extends StatelessWidget {
  const WindowsRightFooter({
    super.key,
    required this.size,
  });
  final double size;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          ' Made with ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size,
            color: kGreyColor,
          ),
        ),
        AvatarGlow(
          glowColor: kGreyColor,
          endRadius: 20.0,
          showTwoGlows: false,
          child: const Icon(
            Icons.favorite,
            color: Colors.red,
          ),
        ),
        // CircleAvatar(
        //   child: Icon(
        //     Icons.favorite,
        //     color: Colors.red,
        //   ),
        // ),
        Text(
          ' in ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size,
            color: kGreyColor,
          ),
        ),
        FlutterLogo(
          size: size,
        ),
        Text(
          ' Flutter  ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size,
            color: kGreyColor,
          ),
        ),
      ],
    );
  }
}

class AndroidRightFooter extends StatelessWidget {
  const AndroidRightFooter({
    super.key,
    this.size = 15,
  });
  final double size;
  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ' Made with ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size,
              color: kGreyColor,
            ),
          ),
          AvatarGlow(
            glowColor: kGreyColor,
            endRadius: 20.0,
            showTwoGlows: false,
            child: const Icon(
              Icons.favorite,
              color: Colors.red,
            ),
          ),
          // CircleAvatar(
          //   child: Icon(
          //     Icons.favorite,
          //     color: Colors.red,
          //   ),
          // ),
          Text(
            ' in ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size,
              color: kGreyColor,
            ),
          ),
          FlutterLogo(
            size: size,
          ),
          Text(
            ' Flutter  ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size,
              color: kGreyColor,
            ),
          ),
        ],
      ),
    );
  }
}

// class WindowsLeftFooter extends StatelessWidget {
//   const WindowsLeftFooter({Key? key, required this.size}) : super(key: key);
//   final double size;
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       'Copyright © 2024 Sivaprasad NK .',
//       style: TextStyle(
//         fontWeight: FontWeight.bold,
//         fontSize: size,
//         fontFamily: 'Roboto',
//         color: kGreyColor,
//       ),
//     );
//   }
// }

class NameLogo extends StatelessWidget {
  const NameLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('SP');
  }
}

// class ProPicWithBlobLottie extends StatelessWidget {
//   const ProPicWithBlobLottie({
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Lottie.asset(blobLottieAssetPath, height: 280),
//         Padding(
//           padding: const EdgeInsets.all(40.0),
//           child: CircleAvatar(
//             radius: 95,
//             backgroundColor: kTransparentColor,
//             backgroundImage: const AssetImage(proPicAssetPath),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class RobotLottie extends StatelessWidget {
//   const RobotLottie({
//     Key? key,
//     required this.showLottie,
//     required this.screenWidth,
//   }) : super(key: key);

//   final bool showLottie;
//   final double screenWidth;

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedOpacity(
//       duration: const Duration(seconds: 1),
//       opacity: showLottie ? 1 : 0,
//       child: Container(
//         margin: EdgeInsets.only(left: screenWidth * 0.15),
//         child: Lottie.asset(
//           'assets/lotties/robot_hello.json',
//           height: 195,
//         ),
//       ),
//     );
//   }
// }

// class DashImageMedium extends StatelessWidget {
//   const DashImageMedium({
//     Key? key,
//     required this.showLottie,
//     required this.screenWidth,
//   }) : super(key: key);

//   final bool showLottie;
//   final double screenWidth;

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedOpacity(
//       duration: const Duration(seconds: 1),
//       opacity: showLottie ? 1 : 0,
//       child: Container(
//         margin: EdgeInsets.only(left: screenWidth * 0.12),
//         child: Image.asset(
//           'assets/images/dash/dash1.png',
//           height: 220,
//         ),
//       ),
//     );
//   }
// }

class AndroidDashImage extends StatelessWidget {
  const AndroidDashImage({
    super.key,
    required this.dashImage,
  });

  final String dashImage;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Image.asset(
        'assets/images/dash/$dashImage.png',
        height: context.screenHeight * 0.18,
      ),
    );
  }
}
