import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/coupon.dart';

abstract class CouponEvent extends Equatable {
  const CouponEvent();

  @override
  List<Object?> get props => [];
}

class LoadCoupons extends CouponEvent {
  const LoadCoupons();
}

class LoadCouponsByActivity extends CouponEvent {
  final String activityId;

  const LoadCouponsByActivity(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class LoadCouponsByProvider extends CouponEvent {
  final String providerId;

  const LoadCouponsByProvider(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

class LoadCouponById extends CouponEvent {
  final String id;

  const LoadCouponById(this.id);

  @override
  List<Object?> get props => [id];
}

class ValidateCouponCode extends CouponEvent {
  final String code;
  final String activityId;

  const ValidateCouponCode(this.code, this.activityId);

  @override
  List<Object?> get props => [code, activityId];
}

class CreateCoupon extends CouponEvent {
  final Coupon coupon;

  const CreateCoupon(this.coupon);

  @override
  List<Object?> get props => [coupon];
}

class UpdateCoupon extends CouponEvent {
  final Coupon coupon;

  const UpdateCoupon(this.coupon);

  @override
  List<Object?> get props => [coupon];
}

class DeleteCoupon extends CouponEvent {
  final String id;

  const DeleteCoupon(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadNegotiations extends CouponEvent {
  final String couponId;

  const LoadNegotiations(this.couponId);

  @override
  List<Object?> get props => [couponId];
}

class CreateNegotiation extends CouponEvent {
  final CouponNegotiation negotiation;

  const CreateNegotiation(this.negotiation);

  @override
  List<Object?> get props => [negotiation];
}

class AcceptNegotiation extends CouponEvent {
  final String negotiationId;

  const AcceptNegotiation(this.negotiationId);

  @override
  List<Object?> get props => [negotiationId];
}

class RejectNegotiation extends CouponEvent {
  final String negotiationId;

  const RejectNegotiation(this.negotiationId);

  @override
  List<Object?> get props => [negotiationId];
}
