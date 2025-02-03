// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:spnk/domain/entity/contact_details.dart';
// import 'package:spnk/utils/extensions/context_extension.dart';
// import 'package:spnk/utils/extensions/string_extensions.dart';
// import 'package:spnk/utils/extensions/widget_extensions.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactItem extends StatefulWidget {
//   const ContactItem({super.key, required this.contactDetails});
//   final ContactDetails contactDetails;

//   @override
//   State<ContactItem> createState() => _ContactItemState();
// }

// class _ContactItemState extends State<ContactItem> {
//   bool isHovering = false;

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (event) {
//         setState(() {
//           isHovering = true;
//         });
//       },
//       onExit: (event) {
//         setState(() {
//           isHovering = false;
//         });
//       },
//       child: Padding(
//         padding: const EdgeInsets.only(
//           top: 25,
//         ),
//         child: GestureDetector(
//           onTap: () async {
//             var link = "";
//             if (widget.contactDetails.type == 'mobile') {
//               final linkList = widget.contactDetails.link.split(',');
//               if (defaultTargetPlatform == TargetPlatform.android ||
//                   defaultTargetPlatform == TargetPlatform.iOS) {
//                 link = linkList.last.trim();
//               } else {
//                 link = linkList.first.trim();
//               }
//             } else {
//               link = widget.contactDetails.link;
//             }
//             //  link TargetPlatform.android
//             //       ? whatsappAndroidLink
//             //       : "https://web.whatsapp.com/send?phone=918086028340";
//             await launchUrl(Uri.parse(link.trim()));
//           },
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 widget.contactDetails.iconName.iconFromString,
//                 color: isHovering ? Colors.cyan : context.primaryColor,
//               ),
//               const SizedBox(width: 20),
//               Text(
//                 widget.contactDetails.details,
//                 style: context.displaySmall.copyWith(
//                   color: isHovering ? Colors.cyan : context.primaryColor,
//                 ),
//               ),
//             ],
//           ),
//         ).showCursorOnHover,
//       ),
//     );
//   }
// }
