import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio_;
import 'package:flutter/material.dart';
import 'package:hyper_commerce/config/security.dart';

import '../services/recent_product/recent_product_service.dart';
import '../services/shopping_list_hive.dart';
import 'global.dart';

class ApiException implements Exception {
  ApiException(this.errorMessage);

  final String errorMessage;

  @override
  String toString() {
    return errorMessage;
  }
}

/// Extracts a human-readable message from a Laravel-style error body:
/// prefers `message`, then the first field error under `errors`.
String _extractValidationMessage(dynamic data) {
  if (data is Map) {
    final message = data['message'];
    if (message != null && message.toString().isNotEmpty) {
      return message.toString();
    }
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
  }
  return 'Validation error';
}

final dio_.BaseOptions _defaultDioOptions = dio_.BaseOptions(
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  sendTimeout: const Duration(seconds: 30),
);

class ApiBaseHelper {
  Future<void> downloadFile(
      {required String url,
        required dio_.CancelToken cancelToken,
        required String savePath,
        required Function(int, int) updateDownloadedPercentage,
      }) async {
    try {
      final dio_.Dio dio = dio_.Dio();
      await dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: updateDownloadedPercentage,
        options: dio_.Options(
          headers: headers,
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      final file = File(savePath);
      if (!await file.exists() || await file.length() == 0) {
        throw ApiException('Downloaded file is empty or does not exist');
      }

      // Check if it's actually a PDF
      final firstBytes = await file.openRead(0, 10).first;
      final headerString = String.fromCharCodes(firstBytes.take(4));

      if (!headerString.startsWith('%PDF')) {
        throw ApiException('Server returned HTML instead of PDF. Check authentication or URL.');
      }

    } on dio_.DioException catch (e) {
      if (e.type == dio_.DioExceptionType.connectionError) {
        throw ApiException('No Internet connection');
      }
      throw ApiException(e.toString());
    } catch (e) {
      throw ApiException(e.toString());
    }
  }


  // POST METHOD
  Future<dynamic> postAPICall(String url, dynamic params) async {
    dio_.Response responseJson;
    final dio_.Dio dio = dio_.Dio(_defaultDioOptions);
    try {
      // For multipart uploads, drop the JSON Content-Type header so Dio can
      // set the correct multipart/form-data header with its boundary.
      final bool isMultipart = params is dio_.FormData;
      final Map<String, String>? reqHeaders = isMultipart
          ? (Map<String, String>.from(headers ?? const {})..remove('Content-Type'))
          : headers;
      final response =
      await dio.post(
        url,
        data: isMultipart ? params : (params.isNotEmpty ? params : {}),
        options: dio_.Options(
          headers: reqHeaders,
          contentType: isMultipart ? 'multipart/form-data' : null,
        ),
      );
      if (kDebugMode) {
        log('response api****$url***********${response.statusCode}');
      }

      responseJson = response;
    } on dio_.DioException catch (e) {
      // DioError handling.
      if (e.response != null) {
        // The server responded but with an error status.
        if(e.response?.statusCode == 401 ){
          throw ApiException(
              '${e.response?.data['message']}');
        } else if(e.response?.statusCode == 422){
          throw ApiException(_extractValidationMessage(e.response?.data));
        } else if(e.response?.statusCode == 500 || e.response?.statusCode == 503){
          throw ApiException(
              'Server error');
        }
        throw ApiException(
            '${e.response?.data['message']}');
      } else {
        throw ApiException('Something Went Wrong: ${e.message}');
      }
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Something went wrong, Server not Responding');
    } on Exception catch (e) {
      throw ApiException('Something Went wrong with ${e.toString()}');
    }
    return responseJson;
  }

  // PUT METHOD
  Future<dynamic> putAPICall(String url, dynamic params) async {
    dio_.Response responseJson;
    final dio_.Dio dio = dio_.Dio(_defaultDioOptions);
    try {
      final response = await dio.put(
        url,
        data: params.isNotEmpty ? params : [],
        options: dio_.Options(
          headers: headers,
        ),
      );
      if (kDebugMode) {
        log('response api****$url***********${response.statusCode}');
      }

      responseJson = response;
    } on dio_.DioException catch (e) {
      // DioError handling.
      if (e.response != null) {
        // The server responded but with an error status.
        if(e.response?.statusCode == 401){
          throw ApiException(
              '${e.response?.data['message']}');
        } else if(e.response?.statusCode == 422){
          throw ApiException(_extractValidationMessage(e.response?.data));
        } else if(e.response?.statusCode == 500 || e.response?.statusCode == 503){
          throw ApiException(
              'Server error');
        }
        throw ApiException(
            '${e.response?.data['message']}');
      } else {
        throw ApiException('Something Went Wrong: ${e.message}');
      }
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Something went wrong, Server not Responding');
    } on Exception catch (e) {
      throw ApiException('Something Went wrong with ${e.toString()}');
    }
    return responseJson;
  }

  Future<dynamic> getAPICall(String url, dynamic params, {bool? isUserApi, BuildContext? context, Map<String, String>? extraHeaders}) async {
    late dio_.Response responseJson;
    final dio_.Dio dio = dio_.Dio(_defaultDioOptions);
    try {
      final response =
      await dio.get(
          url,
          queryParameters: (params is Map<String, dynamic> && params.isNotEmpty) ? params : {},
          options: dio_.Options(headers: {...?headers, ...?extraHeaders})
      );


      responseJson = response;
    } on dio_.DioException catch (e) {
      // DioError handling.
      if(e.response?.statusCode == 401 && isUserApi == true){
        log('Clear User Data  ${e.response?.statusMessage}');
        Global.clearUserData();
        ShoppingListHiveHelper.clearLastList();
        RecentlyViewedService.clear();
      }
      if (e.response != null) {
        // The server responded but with an error status.
        if(e.response?.statusCode == 401){
          throw ApiException(
              '${e.response?.data['message']}');
        }
        else if(e.response?.statusCode == 422){
          throw ApiException(_extractValidationMessage(e.response?.data));
        }
        else if(e.response?.statusCode == 500){
          throw ApiException(
              'Server error');
        } else if(e.response?.statusCode == 403){
          throw ApiException(
              '${e.response?.data['message']}');
        } else if(e.response?.statusCode == 503) {
          throw ApiException('Server error');
        } else if(e.response?.statusCode == 404) {
          throw ApiException(
              '${e.response?.data ['message']}');
        }
        throw ApiException(
            '${e.response?.data ['message']}');
      }
      else {
        throw ApiException('Something Went Wrong: ${e.message}');
      }
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Something went wrong, Server not Responding');
    } on Exception catch (e) {
      throw ApiException('Something Went wrong with ${e.toString()}');
    }
    return responseJson;
  }

  Future<dynamic> deleteAPICall(String url, dynamic params) async {
    dio_.Response responseJson;
    final dio_.Dio dio = dio_.Dio(_defaultDioOptions);
    try {
      final response =
      await dio.delete(
        url,
        data: params.isNotEmpty ? params : [],
        options: dio_.Options(
          headers: headers,
        ),
      );
      if (kDebugMode) {
        print(
            'response api****$url***************${response.statusCode}*********${response.data}');
      }

      responseJson = response;
    } on dio_.DioException catch (e) {
      // DioError handling.
      if (e.response != null) {
        // The server responded but with an error status.
        if(e.response?.statusCode == 401){
          throw ApiException(
              '${e.response?.data['message']}');
        } else if(e.response?.statusCode == 422){
          throw ApiException(_extractValidationMessage(e.response?.data));
        } else if(e.response?.statusCode == 500 || e.response?.statusCode == 503){
          throw ApiException(
              'Server error');
        }
        throw ApiException(
            '${e.response?.data['message']}');
      } else {
        throw ApiException('Something Went Wrong: ${e.message}');
      }
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Something went wrong, Server not Responding');
    } on Exception catch (e) {
      throw ApiException('Something Went wrong with ${e.toString()}');
    }
    return responseJson;
  }

}

class CustomException implements Exception {
  final dynamic message;
  final dynamic prefix;

  CustomException([this.message, this.prefix]);

  @override
  String toString() {
    return '$prefix$message';
  }
}