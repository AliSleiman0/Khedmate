import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';
import '../data/booking_repository.dart';
import '../../payments/data/payment_repository.dart';

class BookingState {
  final String? categoryId;
  final String? categoryName;
  final String description;
  final List<File> photos;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? createdJobId;
  final String? referenceNumber;
  final double? agreedAmount;
  final String currency;
  final String? paymentIntentId;
  final String? transactionId;
  final double? referralDiscountAmount;
  final double? creditApplied;
  final double? chargedAmount;

  const BookingState({
    this.categoryId,
    this.categoryName,
    this.description = '',
    this.photos = const [],
    this.latitude,
    this.longitude,
    this.address,
    this.createdJobId,
    this.referenceNumber,
    this.agreedAmount,
    this.currency = 'usd',
    this.paymentIntentId,
    this.transactionId,
    this.referralDiscountAmount,
    this.creditApplied,
    this.chargedAmount,
  });

  BookingState copyWith({
    String? categoryId,
    String? categoryName,
    String? description,
    List<File>? photos,
    double? latitude,
    double? longitude,
    String? address,
    String? createdJobId,
    String? referenceNumber,
    double? agreedAmount,
    String? currency,
    String? paymentIntentId,
    String? transactionId,
    double? referralDiscountAmount,
    double? creditApplied,
    double? chargedAmount,
  }) =>
      BookingState(
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        description: description ?? this.description,
        photos: photos ?? this.photos,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        address: address ?? this.address,
        createdJobId: createdJobId ?? this.createdJobId,
        referenceNumber: referenceNumber ?? this.referenceNumber,
        agreedAmount: agreedAmount ?? this.agreedAmount,
        currency: currency ?? this.currency,
        paymentIntentId: paymentIntentId ?? this.paymentIntentId,
        transactionId: transactionId ?? this.transactionId,
        referralDiscountAmount:
            referralDiscountAmount ?? this.referralDiscountAmount,
        creditApplied: creditApplied ?? this.creditApplied,
        chargedAmount: chargedAmount ?? this.chargedAmount,
      );
}

class BookingNotifier extends AsyncNotifier<BookingState> {
  @override
  Future<BookingState> build() async => const BookingState();

  void setCategory(String id, String name) {
    final current = state.valueOrNull ?? const BookingState();
    state = AsyncValue.data(
        current.copyWith(categoryId: id, categoryName: name));
  }

  void setDescription(String text) {
    final current = state.valueOrNull ?? const BookingState();
    state = AsyncValue.data(current.copyWith(description: text));
  }

  void addPhoto(File file) {
    final current = state.valueOrNull ?? const BookingState();
    if (current.photos.length >= 3) return;
    state = AsyncValue.data(
        current.copyWith(photos: [...current.photos, file]));
  }

  void removePhoto(int index) {
    final current = state.valueOrNull ?? const BookingState();
    final updated = [...current.photos]..removeAt(index);
    state = AsyncValue.data(current.copyWith(photos: updated));
  }

  void setLocation(double lat, double lng, String address) {
    final current = state.valueOrNull ?? const BookingState();
    state = AsyncValue.data(current.copyWith(
      latitude: lat,
      longitude: lng,
      address: address,
    ));
  }

  void setAmount(double amount) {
    final current = state.valueOrNull ?? const BookingState();
    state = AsyncValue.data(current.copyWith(agreedAmount: amount));
  }

  /// Full payment + booking flow:
  /// 1. Create Stripe PaymentIntent
  /// 2. Present PaymentSheet
  /// 3. Create job
  /// 4. Confirm payment (link to job)
  Future<void> submitBooking() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = const AsyncValue.loading();

    try {
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final bookingRepo = ref.read(bookingRepositoryProvider);

      final intentData = await paymentRepo.createIntent(
        amount: current.agreedAmount!,
        currency: current.currency,
        categoryId: current.categoryId!,
      );

      final paymentIntentId = intentData['paymentIntentId'] as String;
      final clientSecret = intentData['clientSecret'] as String;
      final referralDiscount =
          (intentData['referralDiscountAmount'] as num?)?.toDouble();
      final creditApplied =
          (intentData['creditAppliedAmount'] as num?)?.toDouble();
      final chargedAmount = (intentData['amount'] as num?)?.toDouble();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Khudmati خدمتي',
          style: ThemeMode.light,
        ),
      );

      state = AsyncValue.data(current.copyWith(
        paymentIntentId: paymentIntentId,
        referralDiscountAmount: referralDiscount,
        creditApplied: creditApplied,
        chargedAmount: chargedAmount,
      ));

      await Stripe.instance.presentPaymentSheet();

      state = const AsyncValue.loading();

      final jobResult = await bookingRepo.createJob(
        categoryId: current.categoryId!,
        description: current.description,
        latitude: current.latitude!,
        longitude: current.longitude!,
        address: current.address!,
        photoUrls: [],
      );

      final jobData = jobResult['data'] as Map<String, dynamic>;
      final jobId = jobData['jobId'] as String;
      final refNumber = jobData['referenceNumber'] as String;

      if (current.photos.isNotEmpty) {
        try {
          await bookingRepo.uploadPhotos(jobId, current.photos);
        } catch (_) {}
      }

      final confirmData = await paymentRepo.confirmPayment(
        paymentIntentId: paymentIntentId,
        jobId: jobId,
      );

      final transactionId = confirmData['transactionId'] as String? ?? '';

      state = AsyncValue.data(current.copyWith(
        createdJobId: jobId,
        referenceNumber: refNumber,
        paymentIntentId: paymentIntentId,
        transactionId: transactionId,
        referralDiscountAmount: referralDiscount,
        creditApplied: creditApplied,
        chargedAmount: chargedAmount,
      ));
    } on StripeException catch (e, st) {
      state = AsyncValue.error(
        e.error.localizedMessage ?? 'فشل الدفع، يرجى المحاولة مرة أخرى',
        st,
      );
    } on DioException catch (e, st) {
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(BookingState());
  }
}

final bookingNotifierProvider =
    AsyncNotifierProvider<BookingNotifier, BookingState>(BookingNotifier.new);
