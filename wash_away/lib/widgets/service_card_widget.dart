import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:wash_away/models/service_model.dart';
import 'package:wash_away/controllers/book_controller.dart';

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.service.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Show price based on selected vehicle type if available, otherwise show base price or range
                  Obx(() {
                    // Try to get BookController if available (for booking screen)
                    try {
                      final bookController = Get.find<BookController>();
                      final selectedVehicleType = bookController.selectedVehicleType.value;
                      
                      // If vehicle type is selected and service has pricing for it, show that price
                      if (selectedVehicleType != null && widget.service.pricing != null && widget.service.pricing!.isNotEmpty) {
                        // Map vehicle type to enum value (same logic as in BookController)
                        String mapVehicleTypeToEnum(String? vehicleTypeName) {
                          if (vehicleTypeName == null) return 'sedan';
                          final normalized = vehicleTypeName.toLowerCase().trim();
                          const enumValues = ['sedan', 'suv', 'truck', 'van', 'motorcycle', 'luxury'];
                          if (enumValues.contains(normalized)) return normalized;
                          const mapping = {
                            'car': 'sedan',
                            'sedan': 'sedan',
                            'suv': 'suv',
                            'sport utility vehicle': 'suv',
                            'truck': 'truck',
                            'pickup': 'truck',
                            'pickup truck': 'truck',
                            'van': 'van',
                            'motorcycle': 'motorcycle',
                            'bike': 'motorcycle',
                            'luxury': 'luxury',
                          };
                          return mapping[normalized] ?? 'sedan';
                        }
                        
                        final enumValue = mapVehicleTypeToEnum(selectedVehicleType.name);
                        if (widget.service.pricing!.containsKey(enumValue)) {
                          final vehiclePrice = widget.service.pricing![enumValue];
                          if (vehiclePrice != null && vehiclePrice > 0) {
                            return Text(
                              '\$${vehiclePrice.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: Theme.of(context).textTheme.titleMedium!.color,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }
                        }
                      }
                    } catch (e) {
                      // BookController not available (e.g., in home screen), use default price
                    }
                    
                    // Show base price or price range if multiple vehicle prices exist
                    if (widget.service.pricing != null && widget.service.pricing!.isNotEmpty) {
                      final prices = widget.service.pricing!.values.where((p) => p > 0).toList();
                      if (prices.isNotEmpty) {
                        final minPrice = prices.reduce((a, b) => a < b ? a : b);
                        final maxPrice = prices.reduce((a, b) => a > b ? a : b);
                        if (minPrice != maxPrice) {
                          // Show price range
                          return Text(
                            '\$${minPrice.toStringAsFixed(0)} - \$${maxPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).textTheme.titleMedium!.color,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                      }
                    }
                    
                    // Default: show base price
                    return Text(
                      widget.service.price,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).textTheme.titleMedium!.color,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
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
