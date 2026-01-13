import 'package:car_wash_app/theme/app_colors.dart';
import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/job_detail_controler.dart';
import '../models/job_detail_model.dart';
import 'live_navigation_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;
  
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    // Ensuring the controller is initialized with jobId
    final controller = Get.put(JobDetailController(jobId: jobId));

    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        surfaceTintColor: AppColors.white,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Jobs Detail",
              style: TextStyle(
                fontFamily: "Inter",
                color: AppColors.black,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            Obx(() => Text(
              controller.jobDetail.value.bookingId,
              style: TextStyle(
                fontFamily: "Inter",
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            )),
          ],
        ),
        actions: [Obx(() => _buildStatusBadge(controller))],
        elevation: 0,
      ),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Pixel-Perfect Tracker
              _buildTracker(controller.jobDetail.value.currentStep),
              const SizedBox(height: 16),

              _buildBookingInfo(controller.jobDetail.value),
              const SizedBox(height: 16),

              _buildSectionCard("Customer Details", AppImages.user, [
                _infoTile(
                  null,
                  controller.jobDetail.value.customerName,
                  isTitle: true,
                ),
                _infoTile(
                  null,
                  controller.jobDetail.value.customerPhone,
                  isSub: true,
                ),
              ], icon: Icons.person_outline),
              const SizedBox(height: 16),

              _buildSectionCard(
                "Vehicle Information",
                AppImages.lucide_car,
                [
                  Row(
                    children: [
                      Expanded(
                        child: _infoTile(
                          "Type",
                          controller.jobDetail.value.vehicleType,
                        ),
                      ),
                      Expanded(
                        child: _infoTile(
                          "Model",
                          controller.jobDetail.value.vehicleModel,
                        ),
                      ),
                    ],
                  ),
                  _infoTile("Color", controller.jobDetail.value.vehicleColor),
                ],
                icon: Icons.directions_car_outlined,
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                "Services Detail",
                AppImages.lucide_car,
                [
                  _infoRow("Packages", controller.jobDetail.value.packageName),
                  _infoRow(
                    "Total Price",
                    "\$${controller.jobDetail.value.totalPrice}",
                    isPrice: true,
                  ),
                  _infoRow(
                    "Payment",
                    controller.jobDetail.value.paymentMethod,
                    isBadge: true,
                  ),
                ],
                icon: Icons.settings_outlined,
              ),
              const SizedBox(height: 16),

              _buildSectionCard("Schedule & Location", AppImages.location, [
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        "Date",
                        controller.jobDetail.value.schedule.contains('•')
                            ? controller.jobDetail.value.schedule.split('•')[0].trim()
                            : controller.jobDetail.value.schedule,
                      ),
                    ),
                    Expanded(
                      child: _infoTile(
                        "Time",
                        controller.jobDetail.value.schedule.contains('•')
                            ? controller.jobDetail.value.schedule.split('•')[1].trim()
                            : 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.jobDetail.value.address,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ], icon: Icons.access_time),
              const SizedBox(height: 24),

              _buildBottomActions(controller),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helper Components ---

  Widget _buildStatusBadge(JobDetailController controller) {
    JobStep currentStep = controller.jobDetail.value.currentStep;
    bool isCompleted = currentStep == JobStep.completed;
    bool isWashing = currentStep == JobStep.washing;
    
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? Color(0xFF088B0F).withOpacity(0.12)
            : isWashing
            ? Color(0xFF088B0F).withOpacity(0.12)
            : Color(0xFF6CB6FF).withOpacity(0.36),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          isCompleted
              ? "Completed"
              : isWashing
                  ? "Washing"
                  : "Active",
          style: TextStyle(
            color: isCompleted
                ? const Color(0xFF10B981)
                : isWashing
                ? const Color(0xFF10B981)
                : const Color(0xFF00ACC1),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTracker(JobStep currentStep) {
    double _iconSize = Get.height * 0.04;
    const double _stepWidth = 55;

    return Container(
      height: 120, // Increased height to accommodate status text
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.48),
            spreadRadius: 0,
            blurRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔹 PERFECT LINE (starts & ends at icon centers)
          Positioned(
            top: _iconSize / 2,
            left: _stepWidth / 2,
            right: _stepWidth / 2,
            child: Row(
              children: [
                _trackerLine(true), // Assigned is always active
                _trackerLine(currentStep.index >= JobStep.onTheWay.index),
                _trackerLine(currentStep.index >= JobStep.arrived.index),
                _trackerLine(currentStep.index >= JobStep.washing.index),
              ],
            ),
          ),

          // 🔹 ICONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _trackerStep(
                "Assigned",
                AppImages.tick,
                true, // Always active when job is assigned
                currentStep == JobStep.assigned ? "Getting Ready" : null,
              ),
              _trackerStep(
                "On the way",
                AppImages.tick,
                currentStep.index >= JobStep.onTheWay.index,
                currentStep == JobStep.onTheWay ? "Going" : null,
              ),
              _trackerStep(
                "Arrived",
                AppImages.location,
                currentStep.index >= JobStep.arrived.index,
                currentStep == JobStep.arrived ? "Getting Ready for Washing" : null,
              ),
              _trackerStep(
                "Washing",
                AppImages.washing,
                currentStep.index >= JobStep.washing.index,
                currentStep == JobStep.washing ? "In Progress" : null,
              ),
              _trackerStep(
                "Completed",
                AppImages.completed,
                currentStep.index >= JobStep.completed.index,
                currentStep == JobStep.completed ? "Completed" : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trackerStep(String label, String imagePath, bool isActive, String? statusText) {
    return SizedBox(
      width: 55, // Prevents text width from breaking the line
      child: Column(
        children: [
          Container(
            height: 31,
            width: 31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFF031E3D) : Colors.blue.shade50,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                imagePath,
                color: isActive ? AppColors.white : Color(0xFF0A2540),
              ),
            ),
          ),

          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
          // Show status text below if this is the current step
          if (statusText != null && isActive) ...[
            const SizedBox(height: 2),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF10B981),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _trackerLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? const Color(0xFF031E3D) : Colors.blue.shade50,
      ),
    );
  }

  Widget _buildBookingInfo(JobDetailModel job) {
    return Container(
      height: 89,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: Color(0xFF6CB6FF).withOpacity(0.36),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Booking ID",
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 16,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                job.bookingId,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 20,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Schedule",
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 16,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                job.schedule,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 16,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    String imagePath,
    List<Widget> children, {
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(imagePath, height: 20, width: 20),
              const SizedBox(width: 5),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 20,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(
    String? label,
    String value, {
    bool isTitle = false,
    bool isSub = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTitle ? FontWeight.w500 : FontWeight.w500,
              fontSize: isTitle ? 20 : (isSub ? 15 : 14),
              color: isSub
                  ? AppColors.black.withOpacity(0.48)
                  : AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isPrice = false,
    bool isBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xFF088B0F).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPrice ? AppColors.green : Colors.black,
                fontSize: isPrice ? 16 : 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(JobDetailController controller) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            Get.to(() => LiveNavigationScreen(
              customerAddress: controller.jobDetail.value.address,
              customerName: controller.jobDetail.value.customerName,
              customerLatitude: controller.jobDetail.value.addressLatitude,
              customerLongitude: controller.jobDetail.value.addressLongitude,
            ));
          },
          icon: const Icon(Icons.near_me_outlined, size: 18),
          label: const Text("Open in Maps"),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: Colors.black,
            side: const BorderSide(color: AppColors.black, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          // Show error state if needed
          if (controller.error.value.isNotEmpty) {
            return Center(
              child: Column(
                children: [
                  Text('Error: ${controller.error.value}'),
                  ElevatedButton(
                    onPressed: () => controller.fetchJobDetails(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          // Show action buttons based on current step
          if (controller.jobDetail.value.currentStep == JobStep.assigned) {
            // When assigned/accepted, show "Start Journey" button to go to "On the way"
            return _actionButton(
              "Start Journey",
              const Color(0xFF138EC3),
              AppImages.tick,
              () => controller.updateStep(JobStep.onTheWay),
            );
          } else if (controller.jobDetail.value.currentStep == JobStep.onTheWay) {
            // When on the way, show "Mark Arrived" button
            return _actionButton(
              "Mark Arrived",
              const Color(0xFF138EC3),
              AppImages.location,
              () => controller.updateStep(JobStep.arrived),
            );
          } else if (controller.jobDetail.value.currentStep == JobStep.arrived) {
            // When arrived, show "Start Washing" button
            return _actionButton(
              "Start Washing",
              const Color(0xFF138EC3),
              AppImages.washing,
              () => controller.updateStep(JobStep.washing),
            );
          } else if (controller.jobDetail.value.currentStep == JobStep.washing) {
            // When washing, show "Complete Job" button
            return _actionButton(
              "Complete Job",
              const Color(0xFF10B981),
              AppImages.completed,
              () => _showCompleteDialog(controller),
            );
          }
          
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _actionButton(
    String label,
    Color color,
    String imagePath,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Image.asset(imagePath, height: 12, color: AppColors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    );
  }

  void _showCompleteDialog(JobDetailController controller) {
    final totalPrice = controller.jobDetail.value.totalPrice;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text(
                  "Complete Job",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Confirm the job completion and payment status.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount", style: TextStyle(fontSize: 16)),
                  Text(
                    "\$${totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _paymentOption(totalPrice),
            const SizedBox(height: 24),
            _actionButton(
              "Confirm Completion",
              Colors.green,
              AppImages.send,
              () async {
                // Close dialog first
                Get.back();
                // Complete the job
                await controller.completeJob();
                // Refresh job details to get updated status
                await controller.fetchJobDetails();
              },
            ),
            TextButton(
              onPressed: () {
                // Cancel - just close dialog, don't update status
                Get.back();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption(double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF031E3D)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "💵 Cash Collected",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "I received \$${totalPrice.toStringAsFixed(2)} in cash from customer",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
