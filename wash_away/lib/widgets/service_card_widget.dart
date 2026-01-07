import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wash_away/models/service_model.dart';

import '../Helpers/endl_helper.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
class ServiceCardWidget extends StatefulWidget {
  final Service service;
  final bool showBorder;
   ServiceCardWidget({super.key, required this.service, this.showBorder = true});

  @override
  State<ServiceCardWidget> createState() => _ServiceCardWidgetState();
}

class _ServiceCardWidgetState extends State<ServiceCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: widget.showBorder
            ? Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.25),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.service.iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                widget.service.imagePath,
                width: MediaQuery.of(context).size.width * 0.1,
                height: MediaQuery.of(context).size.height * 0.08,
              ),
            ),
            // title: Row(
            //   children: [
            //     Flexible(
            //       child: Text(
            //         widget.service.title,
            //         style: Theme.of(context).textTheme.titleMedium,
            //       ),
            //     ),
            //     if (widget.service.isPopular) ...[
            //       const SizedBox(width: 10),
            //       Container(
            //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //         decoration: BoxDecoration(
            //           color: const Color(0xFFFFEFBD),
            //           borderRadius: BorderRadius.circular(6),
            //         ),
            //         child: Text(
            //           'Popular',
            //           style: GoogleFonts.inter(
            //             color: Color(0xffBB732F),
            //             fontSize: 10,
            //             fontWeight: FontWeight.w600,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ],
            // ),
            subtitle: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    widget.service.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.service.isPopular) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFBD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Popular',
                      style: GoogleFonts.inter(
                        color: Color(0xffBB732F),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
             
                  Text(
                    widget.service.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                   Text(
                    widget.service.price,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).textTheme.titleMedium!.color,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).textTheme.titleMedium!.color,
                  ),
              
                
              
                ],
              ),
              Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 90 min (Time)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.service.durationMin.toString(),
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'min',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Full exterior wash
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '•',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                          : LightTheme.textPrimary.withValues(alpha: 0.25),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                         splitFirstWord( widget.service.features[0]),
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Interior vacuum
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '•',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                          : LightTheme.textPrimary.withValues(alpha: 0.25),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        splitFirstWord(   widget.service.features[1],) ,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ],
          ),

              ] 
            ),
            // trailing: Row(
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     Text(
            //       widget.service.price,
            //       style: GoogleFonts.inter(
            //         color: Theme.of(context).textTheme.titleMedium!.color,
            //         fontSize: 20,
            //         fontWeight: FontWeight.w600,
            //       ),
            //     ),
            //     const SizedBox(width: 8),
            //     Icon(
            //       Icons.arrow_forward_ios,
            //       size: 16,
            //       color: Theme.of(context).textTheme.titleMedium!.color,
            //     ),
            //   ],
            // ),
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     // 90 min (Time)
          //     Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(Icons.access_time, size: 16),
          //         const SizedBox(width: 4),
          //         Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             Text(
          //               widget.service.durationMin.toString(),
          //               style: GoogleFonts.inter(
          //                 color: Theme.of(context).brightness == Brightness.dark
          //                     ? DarkTheme.textPrimary.withValues(alpha: 0.25)
          //                     : LightTheme.textPrimary.withValues(alpha: 0.25),
          //                 fontSize: 11,
          //               ),
          //             ),
          //             Text(
          //               'min',
          //               style: GoogleFonts.inter(
          //                 color: Theme.of(context).brightness == Brightness.dark
          //                     ? DarkTheme.textPrimary.withValues(alpha: 0.25)
          //                     : LightTheme.textPrimary.withValues(alpha: 0.25),
          //                 fontSize: 11,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //     // Full exterior wash
          //     Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Text(
          //           '•',
          //           style: GoogleFonts.inter(
          //             color: Theme.of(context).brightness == Brightness.dark
          //                 ? DarkTheme.textPrimary.withValues(alpha: 0.25)
          //                 : LightTheme.textPrimary.withValues(alpha: 0.25),
          //             fontSize: 11,
          //           ),
          //         ),
          //         const SizedBox(width: 4),
          //         Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             Text(
          //                splitFirstWord( widget.service.features[0]),
          //               style: GoogleFonts.inter(
          //                 color: Theme.of(context).brightness == Brightness.dark
          //                     ? DarkTheme.textPrimary.withValues(alpha: 0.25)
          //                     : LightTheme.textPrimary.withValues(alpha: 0.25),
          //                 fontSize: 11,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //     const SizedBox(width: 12),
          //     // Interior vacuum
          //     Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Text(
          //           '•',
          //           style: GoogleFonts.inter(
          //             color: Theme.of(context).brightness == Brightness.dark
          //                 ? DarkTheme.textPrimary.withValues(alpha: 0.25)
          //                 : LightTheme.textPrimary.withValues(alpha: 0.25),
          //             fontSize: 11,
          //           ),
          //         ),
          //         const SizedBox(width: 4),
          //         Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             Text(
          //               splitFirstWord(   widget.service.features[1],) ,
          //               style: GoogleFonts.inter(
          //                 color: Theme.of(context).brightness == Brightness.dark
          //                     ? DarkTheme.textPrimary.withValues(alpha: 0.25)
          //                     : LightTheme.textPrimary.withValues(alpha: 0.25),
          //                 fontSize: 11,
          //               ),
          //             ),

          //           ],
          //         ),
          //       ],
          //     ),
          //   ],
          // ),

        ],
      ),
    );
  }
}
