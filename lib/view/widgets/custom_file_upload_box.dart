import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../core/constants/app_colors.dart';

class CustomFileUploadBox extends StatelessWidget {
  final VoidCallback? onUpload;
  final String? fileName;

  const CustomFileUploadBox({this.onUpload, this.fileName, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpload,
      child: DottedBorder(
        color: AppColors.grey300,
        borderType: BorderType.RRect,
        radius: const Radius.circular(17),
        strokeWidth: 2,
        dashPattern: const [8, 4],
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload, size: 36, color: AppColors.grey600),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Upload a ",
                  style: TextStyle(fontSize: 17, color: AppColors.mutedText),
                  children: [
                    TextSpan(
                      text: "file",
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(
                      text: " or drag and drop\nPNG, JPG, GIF up to 10MB",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (fileName != null && fileName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Text(
                    fileName!,
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 15,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
