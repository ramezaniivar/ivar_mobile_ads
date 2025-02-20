import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

import 'result.dart';

class MyException {
  static Future<Result<T>> handleError<T>(dynamic err) async {
    log("$err");
    if (err is DioException) {
      final statusCode = err.response?.statusCode;
      try {
        // if (err.response?.data["message"] != null) {
        //   return Result.error(err.response!.data["message"].toString());
        // }

        String myError = "";

        if (err.response?.data != null) {
          myError = '${err.response?.data}';
        } else {
          myError = err.message ?? 'request error';
          // myError =
          //     "${err.response?.data?["message"] ?? "request error"}${err.response?.data?["data"] != null ? "\n" : ""}${err.response?.data?["data"] ?? ""}";
        }

        return Result.error(myError, statusCode: statusCode ?? 400);
      } catch (err) {
        return Result.error("request error");
      }
    }

    if (err is WebSocketException) {
      return Result.error(err.message);
    }

    return Result.error("client error");
  }
}
