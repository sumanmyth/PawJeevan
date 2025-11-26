import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Create a MultipartFile from an [XFile], attempting to set a correct
/// Content-Type for common image formats including HEIC/HEIF.
Future<MultipartFile> multipartFileFromXFile(XFile file) async {
  final bytes = await file.readAsBytes();
  String filename = file.name;
  if (filename.isEmpty) filename = p.basename(file.path);

  final origExt = p.extension(filename).toLowerCase().replaceFirst('.', '');
  String subtype = 'jpeg';
  // We'll attempt to compress images on non-web platforms for faster uploads.
  Uint8List outBytes = bytes;
  String outFilename = filename;

  if (!kIsWeb) {
    try {
      // Adaptive compression: choose settings based on original byte size.
      final size = bytes.lengthInBytes;
      // thresholds in bytes
      const smallThreshold = 150 * 1024; // 150KB
      const mediumThreshold = 800 * 1024; // 800KB
      const largeThreshold = 2 * 1024 * 1024; // 2MB

      bool doCompress = true;
      int quality = 60;
      int minWidth = 1280;
      int minHeight = 720;

      if (size <= smallThreshold) {
        // Small image: skip compression to preserve quality
        doCompress = false;
      } else if (size <= mediumThreshold) {
        // Medium: light compression
        quality = 75;
        minWidth = 1280;
        minHeight = 720;
      } else if (size <= largeThreshold) {
        // Large: moderate compression
        quality = 60;
        minWidth = 1280;
        minHeight = 720;
      } else {
        // Very large: aggressive compression and downscale
        quality = 50;
        minWidth = 1024;
        minHeight = 768;
      }

      if (doCompress) {
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          quality: quality,
          minWidth: minWidth,
          minHeight: minHeight,
          format: CompressFormat.jpeg,
        );
        if (compressed.isNotEmpty) {
          outBytes = Uint8List.fromList(compressed);
          outFilename = '${p.basenameWithoutExtension(filename)}.jpg';
          subtype = 'jpeg';
        }
      } else {
        // Keep original bytes and determine subtype from original extension
        switch (origExt) {
          case 'jpg':
          case 'jpeg':
            subtype = 'jpeg';
            break;
          case 'png':
            subtype = 'png';
            break;
          case 'gif':
            subtype = 'gif';
            break;
          case 'webp':
            subtype = 'webp';
            break;
          case 'avif':
            subtype = 'avif';
            break;
          case 'heic':
          case 'heif':
            subtype = 'heic';
            break;
          default:
            subtype = 'jpeg';
        }
      }
    } catch (e) {
      // If compression fails, fall back to original bytes.
    }
  } else {
    // For web keep original subtype when possible
    switch (origExt) {
      case 'jpg':
      case 'jpeg':
        subtype = 'jpeg';
        break;
      case 'png':
        subtype = 'png';
        break;
      case 'gif':
        subtype = 'gif';
        break;
      case 'webp':
        subtype = 'webp';
        break;
      case 'avif':
        subtype = 'avif';
        break;
      case 'heic':
      case 'heif':
        subtype = 'heic';
        break;
      default:
        subtype = 'jpeg';
    }
  }

  return MultipartFile.fromBytes(
    outBytes,
    filename: outFilename,
    contentType: MediaType('image', subtype),
  );
}

Future<MultipartFile> multipartFileFromBytes(List<int> bytes, String filename) async {
  final origExt = p.extension(filename).toLowerCase().replaceFirst('.', '');
  String subtype = 'jpeg';
  Uint8List outBytes = Uint8List.fromList(bytes);
  String outFilename = filename;

  if (!kIsWeb) {
    try {
      // Adaptive compression by size
      final size = outBytes.lengthInBytes;
      const smallThreshold = 150 * 1024;
      const mediumThreshold = 800 * 1024;
      const largeThreshold = 2 * 1024 * 1024;

      bool doCompress = true;
      int quality = 60;
      int minWidth = 1280;
      int minHeight = 720;

      if (size <= smallThreshold) {
        doCompress = false;
      } else if (size <= mediumThreshold) {
        quality = 75;
      } else if (size <= largeThreshold) {
        quality = 60;
      } else {
        quality = 50;
        minWidth = 1024;
        minHeight = 768;
      }

      if (doCompress) {
        final compressed = await FlutterImageCompress.compressWithList(
          outBytes,
          quality: quality,
          minWidth: minWidth,
          minHeight: minHeight,
          format: CompressFormat.jpeg,
        );
        if (compressed.isNotEmpty) {
          outBytes = Uint8List.fromList(compressed);
          outFilename = '${p.basenameWithoutExtension(filename)}.jpg';
          subtype = 'jpeg';
        }
      } else {
        // preserve original subtype for small images
        switch (origExt) {
          case 'jpg':
          case 'jpeg':
            subtype = 'jpeg';
            break;
          case 'png':
            subtype = 'png';
            break;
          case 'gif':
            subtype = 'gif';
            break;
          case 'webp':
            subtype = 'webp';
            break;
          case 'avif':
            subtype = 'avif';
            break;
          case 'heic':
          case 'heif':
            subtype = 'heic';
            break;
          default:
            subtype = 'jpeg';
        }
      }
    } catch (e) {
      // ignore and use original
    }
  } else {
    switch (origExt) {
      case 'jpg':
      case 'jpeg':
        subtype = 'jpeg';
        break;
      case 'png':
        subtype = 'png';
        break;
      case 'gif':
        subtype = 'gif';
        break;
      case 'webp':
        subtype = 'webp';
        break;
      case 'avif':
        subtype = 'avif';
        break;
      case 'heic':
      case 'heif':
        subtype = 'heic';
        break;
      default:
        subtype = 'jpeg';
    }
  }

  return MultipartFile.fromBytes(outBytes, filename: outFilename, contentType: MediaType('image', subtype));
}

/// Create a MultipartFile from a local file path or a web blob URL.
/// This will fetch/read bytes and then call `multipartFileFromBytes` to apply compression.
Future<MultipartFile> multipartFileFromPath(String path) async {
  if (kIsWeb) {
    // On web, paths from image picker are often blob URLs — fetch as bytes
    try {
      final resp = await Dio().get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = resp.data!;
      final filename = p.basename(path);
      return await multipartFileFromBytes(bytes, filename);
    } catch (e) {
      // As a last resort, create a MultipartFile without compression (may fail on web)
      return MultipartFile.fromBytes([], filename: p.basename(path));
    }
  } else {
    try {
      final bytes = await File(path).readAsBytes();
      final filename = p.basename(path);
      return await multipartFileFromBytes(bytes, filename);
    } catch (e) {
      // Fallback: attempt to create from file (uncompressed)
      return MultipartFile.fromFile(path, filename: p.basename(path));
    }
  }
}
