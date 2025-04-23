import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/coupon/coupon_event.dart';
import 'package:flutter_activity_app/bloc/coupon/coupon_state.dart';
import 'package:flutter_activity_app/models/coupon.dart';
import 'package:flutter_activity_app/repositories/coupon_repository.dart';

class CouponBloc extends Bloc<CouponEvent, CouponState> {
  final CouponRepository _couponRepository;

  CouponBloc(this._couponRepository) : super(const CouponInitial()) {
    on<LoadCoupons>(_onLoadCoupons);
    on<LoadCouponsByActivity>(_onLoadCouponsByActivity);
    on<LoadCouponsByProvider>(_onLoadCouponsByProvider);
    on<LoadCouponById>(_onLoadCouponById);
    on<ValidateCouponCode>(_onValidateCouponCode);
    on<CreateCoupon>(_onCreateCoupon);
    on<UpdateCoupon>(_onUpdateCoupon);
    on<DeleteCoupon>(_onDeleteCoupon);
    on<LoadNegotiations>(_onLoadNegotiations);
    on<CreateNegotiation>(_onCreateNegotiation);
    on<AcceptNegotiation>(_onAcceptNegotiation);
    on<RejectNegotiation>(_onRejectNegotiation);
  }

  Future<void> _onLoadCoupons(
    LoadCoupons event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      final coupons = await _couponRepository.getCoupons();
      emit(CouponsLoaded(coupons));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onLoadCouponsByActivity(
    LoadCouponsByActivity event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      final coupons = await _couponRepository.getCouponsByActivity(event.activityId);
      emit(CouponsLoaded(coupons));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onLoadCouponsByProvider(
    LoadCouponsByProvider event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      final coupons = await _couponRepository.getCouponsByProvider(event.providerId);
      emit(CouponsLoaded(coupons));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onLoadCouponById(
    LoadCouponById event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      final coupon = await _couponRepository.getCouponById(event.id);
      emit(CouponLoaded(coupon));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onValidateCouponCode(
    ValidateCouponCode event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      final coupon = await _couponRepository.getCouponByCode(event.code);
      
      // Validate that the coupon is for the correct activity
      if (coupon.activityId != event.activityId) {
        emit(const CouponError('This coupon is not valid for this activity'));
        return;
      }
      
      // Validate that the coupon is active and approved
      if (!coupon.isValid) {
        emit(const CouponError('This coupon is not valid or has expired'));
        return;
      }
      
      // Calculate discount amount (for a sample price of 100)
      final discountAmount = coupon.calculateDiscount(100);
      
      emit(CouponValidated(coupon, discountAmount));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onCreateCoupon(
    CreateCoupon event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      final coupon = await _couponRepository.createCoupon(event.coupon);
      emit(CouponCreated(coupon));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onUpdateCoupon(
    UpdateCoupon event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      final coupon = await _couponRepository.updateCoupon(event.coupon);
      emit(CouponUpdated(coupon));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onDeleteCoupon(
    DeleteCoupon event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      await _couponRepository.deleteCoupon(event.id);
      emit(CouponDeleted(event.id));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onLoadNegotiations(
    LoadNegotiations event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      final negotiations = await _couponRepository.getNegotiations(event.couponId);
      emit(NegotiationsLoaded(negotiations));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onCreateNegotiation(
    CreateNegotiation event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      final negotiation = await _couponRepository.createNegotiation(event.negotiation);
      emit(NegotiationCreated(negotiation));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onAcceptNegotiation(
    AcceptNegotiation event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      // Get the negotiation
      final negotiations = await _couponRepository.getNegotiations('');
      final negotiation = negotiations.firstWhere(
        (n) => n.id == event.negotiationId,
        orElse: () => throw Exception('Negotiation not found'),
      );
      
      // Update the negotiation status
      final updatedNegotiation = CouponNegotiation(
        id: negotiation.id,
        couponId: negotiation.couponId,
        providerId: negotiation.providerId,
        adminId: negotiation.adminId,
        proposedValue: negotiation.proposedValue,
        message: negotiation.message,
        createdAt: negotiation.createdAt,
        isProviderProposal: negotiation.isProviderProposal,
        status: 'accepted',
      );
      
      final result = await _couponRepository.updateNegotiation(updatedNegotiation);
      
      // Get the coupon and update it with the negotiated value
      final coupon = await _couponRepository.getCouponById(negotiation.couponId);
      final updatedCoupon = coupon.copyWith(
        value: negotiation.proposedValue,
        isApproved: true,
      );
      
      await _couponRepository.updateCoupon(updatedCoupon);
      
      emit(NegotiationUpdated(result));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> _onRejectNegotiation(
    RejectNegotiation event,
    Emitter<CouponState> emit,
  ) async {
    emit(const CouponLoading());
    try {
      // Get the negotiation
      final negotiations = await _couponRepository.getNegotiations('');
      final negotiation = negotiations.firstWhere(
        (n) => n.id == event.negotiationId,
        orElse: () => throw Exception('Negotiation not found'),
      );
      
      // Update the negotiation status
      final updatedNegotiation = CouponNegotiation(
        id: negotiation.id,
        couponId: negotiation.couponId,
        providerId: negotiation.providerId,
        adminId: negotiation.adminId,
        proposedValue: negotiation.proposedValue,
        message: negotiation.message,
        createdAt: negotiation.createdAt,
        isProviderProposal: negotiation.isProviderProposal,
        status: 'rejected',
      );
      
      final result = await _couponRepository.updateNegotiation(updatedNegotiation);
      emit(NegotiationUpdated(result));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }
}
