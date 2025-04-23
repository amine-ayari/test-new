import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/coupon.dart';

abstract class CouponState extends Equatable {
  const CouponState();

  @override
  List<Object?> get props => [];
}

class CouponInitial extends CouponState {
  const CouponInitial();
}

class CouponLoading extends CouponState {
  const CouponLoading();
}

class CouponsLoaded extends CouponState {
  final List<Coupon> coupons;

  const CouponsLoaded(this.coupons);

  @override
  List<Object?> get props => [coupons];
}

class CouponLoaded extends CouponState {
  final Coupon coupon;

  const CouponLoaded(this.coupon);

  @override
  List<Object?> get props => [coupon];
}

class CouponValidated extends CouponState {
  final Coupon coupon;
  final double discountAmount;

  const CouponValidated(this.coupon, this.discountAmount);

  @override
  List<Object?> get props => [coupon, discountAmount];
}

class CouponCreated extends CouponState {
  final Coupon coupon;

  const CouponCreated(this.coupon);

  @override
  List<Object?> get props => [coupon];
}

class CouponUpdated extends CouponState {
  final Coupon coupon;

  const CouponUpdated(this.coupon);

  @override
  List<Object?> get props => [coupon];
}

class CouponDeleted extends CouponState {
  final String id;

  const CouponDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

class NegotiationsLoaded extends CouponState {
  final List<CouponNegotiation> negotiations;

  const NegotiationsLoaded(this.negotiations);

  @override
  List<Object?> get props => [negotiations];
}

class NegotiationCreated extends CouponState {
  final CouponNegotiation negotiation;

  const NegotiationCreated(this.negotiation);

  @override
  List<Object?> get props => [negotiation];
}

class NegotiationUpdated extends CouponState {
  final CouponNegotiation negotiation;

  const NegotiationUpdated(this.negotiation);

  @override
  List<Object?> get props => [negotiation];
}

class CouponError extends CouponState {
  final String message;

  const CouponError(this.message);

  @override
  List<Object?> get props => [message];
}
