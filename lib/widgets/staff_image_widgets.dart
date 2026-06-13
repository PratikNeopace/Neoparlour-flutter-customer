import 'dart:convert';
import '../../core/utils/flushbar_helper.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_assets.dart';

import 'premium_image.dart';

/// A senior-level reusable widget for displaying staff images with fallback logic.
class StaffAvatar extends StatelessWidget {
  final String? imageAsBase64;
  final String? imagePath;
  final String? imageUrl;
  final String? gender;
  final double? width;
  final double? height;
  final double size;
  final double borderRadius;

  const StaffAvatar({
    super.key,
    this.imageAsBase64,
    this.imagePath,
    this.imageUrl,
    this.gender,
    this.width,
    this.height,
    this.size = 80.0,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? size,
      height: height ?? size,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    // 1. Priority: Local File Path (for previewing picked images)
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    // 2. Priority: Base64 String (from API)
    if (imageAsBase64 != null && imageAsBase64!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(imageAsBase64!),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
        return _buildFallback();
      }
    }

    // 3. Priority: Network Image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return PremiumImageWidget(
        imageUrl: imageUrl,
        width: width ?? size,
        height: height ?? size,
        borderRadius: BorderRadius.circular(borderRadius),
        fallbackWidget: _buildFallback(),
      );
    }

    // 4. Fallback: Gender-based SVG
    return _buildFallback();
  }

  Widget _buildFallback() {
    final isFemale = gender?.toLowerCase() == 'female';
    final assetPath = isFemale ? AppAssets.femaleIcon : AppAssets.maleIcon;

    return Padding(
      padding: EdgeInsets.all(size * 0.15),
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Icon(
          Icons.person,
          size: size * 0.5,
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// A component for picking multiple (2) images for a staff member.
class MultiImagePickerSection extends StatefulWidget {
  final Function(List<XFile>) onImagesPicked;
  final int maxImages;

  const MultiImagePickerSection({
    super.key,
    required this.onImagesPicked,
    this.maxImages = 2,
  });

  @override
  State<MultiImagePickerSection> createState() => _MultiImagePickerSectionState();
}

class _MultiImagePickerSectionState extends State<MultiImagePickerSection> {
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= widget.maxImages) {      FlushbarHelper.show(context, "Maximum ${widget.maxImages} images allowed");

      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
        widget.onImagesPicked(_selectedImages);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Staff Photos",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "${_selectedImages.length}/${widget.maxImages}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // List of selected images
            ..._selectedImages.asMap().entries.map((entry) {
              int idx = entry.key;
              XFile file = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    StaffAvatar(
                      imagePath: file.path,
                      size: 100,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(idx);
                          });
                          widget.onImagesPicked(_selectedImages);
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Add button (if below limit)
            if (_selectedImages.length < widget.maxImages)
              GestureDetector(
                onTap: () => _showPickerOptions(),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 30),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
