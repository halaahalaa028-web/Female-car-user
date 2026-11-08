import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ride_sharing_user_app/util/images.dart';

class ImageWidget extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final String? placeholder;
  final double radius;
  
  const ImageWidget({
    super.key, 
    required this.image, 
    this.height, 
    this.width, 
    this.fit = BoxFit.cover, 
    this.placeholder = Images.placeholder, 
    this.radius = 0
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: image,
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
        // Add memory and disk cache limits
        memCacheWidth: width != null ? (width! * 2).toInt() : null,
        memCacheHeight: height != null ? (height! * 2).toInt() : null,
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => Image.asset(
          placeholder ?? Images.placeholder, 
          height: height, 
          width: width, 
          fit: fit ?? BoxFit.cover,
          cacheWidth: width != null ? (width! * 2).toInt() : null,
          cacheHeight: height != null ? (height! * 2).toInt() : null,
        ),
        errorWidget: (c, o, s) => Image.asset(
          placeholder ?? Images.placeholder, 
          height: height, 
          width: width, 
          fit: fit ?? BoxFit.cover
        ),
      ),
    );
  }
}
