import 'dart:ffi';

import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/image/color_space_type.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

/// Implements some stateless image conversion methods.
///
/// This class is an internal helper.
class ImageConversions {
  static Image convertRgbTensorBufferToImage(TensorBuffer buffer) {
    List<int> shape = buffer.getShape();
    ColorSpaceType rgb = ColorSpaceType.RGB;
    rgb.assertShape(shape);

    int h = rgb.getHeight(shape);
    int w = rgb.getWidth(shape);
    Image image = Image(width: w, height: h);

    List<int> rgbValues = buffer.getIntList();
    assert(rgbValues.length == w * h * 3);

    for (int i = 0, j = 0, wi = 0, hi = 0; j < rgbValues.length; i++) {
      int r = rgbValues[j++];
      int g = rgbValues[j++];
      int b = rgbValues[j++];
      image.setPixelRgba(wi, hi, r, g, b, 0xff);
      wi++;
      if (wi % w == 0) {
        wi = 0;
        hi++;
      }
    }

    return image;
  }

  static Image convertGrayscaleTensorBufferToImage(TensorBuffer buffer) {
    // Convert buffer into Uint8 as needed.
    TensorBuffer uint8Buffer = buffer.getDataType() == TfLiteType.uint8
        ? buffer
        : TensorBuffer.createFrom(buffer, TfLiteType.uint8);

    final shape = uint8Buffer.getShape();
    final grayscale = ColorSpaceType.GRAYSCALE;
    grayscale.assertShape(shape);

    final image = Image.fromBytes(
      width: grayscale.getWidth(shape),
      height: grayscale.getHeight(shape),
      bytes: uint8Buffer.getBuffer(),
      format: Format.uint8, // Format.luminance, //TODO! check
    );

    return image;
  }

  static void convertImageToTensorBuffer(Image image, TensorBuffer buffer) {
    int w = image.width;
    int h = image.height;
    ImageData imgData = image.data!;
    int flatSize = w * h * 3;
    List<int> shape = [h, w, 3];
    switch (buffer.getDataType()) {
      case TfLiteType.uint8:
        List<int> byteArr = List.filled(flatSize, 0);
        int j = 0;
        for (final pixel in imgData) {
          byteArr[j++] = (pixel.r).toInt();
          byteArr[j++] = (pixel.g).toInt();
          byteArr[j++] = (pixel.b).toInt();
        }
        buffer.loadList(byteArr, shape: shape);
        break;
      case TfLiteType.float32:
        List<double> floatArr = List.filled(flatSize, 0.0);
        int j = 0;
        for (final pixel in imgData) {
          floatArr[j++] = (pixel.r).toDouble();
          floatArr[j++] = (pixel.g).toDouble();
          floatArr[j++] = (pixel.b).toDouble();
        }
        buffer.loadList(floatArr, shape: shape);
        break;
      default:
        throw StateError(
            "${buffer.getDataType()} is unsupported with TensorBuffer.");
    }
  }
}
