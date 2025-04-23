// TODO Implement this library.


import 'dart:convert';
import 'package:flutter_activity_app/models/coupon.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class CouponRepository {
  Future<List<Coupon>> getCoupons();
  Future<List<Coupon>> getCouponsByActivity(String activityId);
  Future<List<Coupon>> getCouponsByProvider(String providerId);
  Future<Coupon> getCouponById(String id);
  Future<Coupon> getCouponByCode(String code);
  Future<Coupon> createCoupon(Coupon coupon);
  Future<Coupon> updateCoupon(Coupon coupon);
  Future<bool> deleteCoupon(String id);
  Future<List<CouponNegotiation>> getNegotiations(String couponId);
  Future<CouponNegotiation> createNegotiation(CouponNegotiation negotiation);
  Future<CouponNegotiation> updateNegotiation(CouponNegotiation negotiation);
}

class CouponRepositoryImpl implements CouponRepository {
  final ApiService _apiService;
  final SharedPreferences _sharedPreferences;
  
  // Keys for SharedPreferences
  static const String _couponsKey = 'coupons';
  static const String _negotiationsKey = 'coupon_negotiations';
  
  CouponRepositoryImpl(this._apiService, this._sharedPreferences);
  
  @override
  Future<List<Coupon>> getCoupons() async {
    try {
      // In a real app, we would fetch from API
      // final response = await _apiService.get('/coupons');
      
      // For demo purposes, we'll use SharedPreferences
      final couponsJson = _sharedPreferences.getString(_couponsKey);
      
      if (couponsJson != null) {
        final List<dynamic> decodedList = jsonDecode(couponsJson);
        return decodedList.map((item) => Coupon.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get coupons: $e');
    }
  }
  
  @override
  Future<List<Coupon>> getCouponsByActivity(String activityId) async {
    try {
      final coupons = await getCoupons();
      return coupons.where((coupon) => coupon.activityId == activityId).toList();
    } catch (e) {
      throw Exception('Failed to get coupons by activity: $e');
    }
  }
  
  @override
  Future<List<Coupon>> getCouponsByProvider(String providerId) async {
    try {
      final coupons = await getCoupons();
      return coupons.where((coupon) => coupon.providerId == providerId).toList();
    } catch (e) {
      throw Exception('Failed to get coupons by provider: $e');
    }
  }
  
  @override
  Future<Coupon> getCouponById(String id) async {
    try {
      final coupons = await getCoupons();
      final coupon = coupons.firstWhere(
        (coupon) => coupon.id == id,
        orElse: () => throw Exception('Coupon not found'),
      );
      return coupon;
    } catch (e) {
      throw Exception('Failed to get coupon by id: $e');
    }
  }
  
  @override
  Future<Coupon> getCouponByCode(String code) async {
    try {
      final coupons = await getCoupons();
      final coupon = coupons.firstWhere(
        (coupon) => coupon.code.toLowerCase() == code.toLowerCase(),
        orElse: () => throw Exception('Coupon not found'),
      );
      return coupon;
    } catch (e) {
      throw Exception('Failed to get coupon by code: $e');
    }
  }
  
  @override
  Future<Coupon> createCoupon(Coupon coupon) async {
    try {
      // In a real app, we would create via API
      // final response = await _apiService.post('/coupons', body: coupon.toJson());
      
      // For demo purposes, we'll use SharedPreferences
      final coupons = await getCoupons();
      
      // Generate a unique ID
      final newCoupon = coupon.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      
      coupons.add(newCoupon);
      
      await _sharedPreferences.setString(_couponsKey, jsonEncode(coupons.map((c) => c.toJson()).toList()));
      
      return newCoupon;
    } catch (e) {
      throw Exception('Failed to create coupon: $e');
    }
  }
  
  @override
  Future<Coupon> updateCoupon(Coupon coupon) async {
    try {
      // In a real app, we would update via API
      // final response = await _apiService.put('/coupons/${coupon.id}', body: coupon.toJson());
      
      // For demo purposes, we'll use SharedPreferences
      final coupons = await getCoupons();
      
      final index = coupons.indexWhere((c) => c.id == coupon.id);
      if (index == -1) {
        throw Exception('Coupon not found');
      }
      
      coupons[index] = coupon;
      
      await _sharedPreferences.setString(_couponsKey, jsonEncode(coupons.map((c) => c.toJson()).toList()));
      
      return coupon;
    } catch (e) {
      throw Exception('Failed to update coupon: $e');
    }
  }
  
  @override
  Future<bool> deleteCoupon(String id) async {
    try {
      // In a real app, we would delete via API
      // final response = await _apiService.delete('/coupons/$id');
      
      // For demo purposes, we'll use SharedPreferences
      final coupons = await getCoupons();
      
      final filteredCoupons = coupons.where((c) => c.id != id).toList();
      
      await _sharedPreferences.setString(_couponsKey, jsonEncode(filteredCoupons.map((c) => c.toJson()).toList()));
      
      return true;
    } catch (e) {
      throw Exception('Failed to delete coupon: $e');
    }
  }
  
  @override
  Future<List<CouponNegotiation>> getNegotiations(String couponId) async {
    try {
      // In a real app, we would fetch from API
      // final response = await _apiService.get('/coupon-negotiations?couponId=$couponId');
      
      // For demo purposes, we'll use SharedPreferences
      final negotiationsJson = _sharedPreferences.getString(_negotiationsKey);
      
      if (negotiationsJson != null) {
        final List<dynamic> decodedList = jsonDecode(negotiationsJson);
        final allNegotiations = decodedList.map((item) => CouponNegotiation.fromJson(item)).toList();
        return allNegotiations.where((n) => n.couponId == couponId).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get negotiations: $e');
    }
  }
  
  @override
  Future<CouponNegotiation> createNegotiation(CouponNegotiation negotiation) async {
    try {
      // In a real app, we would create via API
      // final response = await _apiService.post('/coupon-negotiations', body: negotiation.toJson());
      
      // For demo purposes, we'll use SharedPreferences
      final negotiationsJson = _sharedPreferences.getString(_negotiationsKey);
      List<CouponNegotiation> negotiations = [];
      
      if (negotiationsJson != null) {
        final List<dynamic> decodedList = jsonDecode(negotiationsJson);
        negotiations = decodedList.map((item) => CouponNegotiation.fromJson(item)).toList();
      }
      
      // Generate a unique ID
      final newNegotiation = CouponNegotiation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        couponId: negotiation.couponId,
        providerId: negotiation.providerId,
        adminId: negotiation.adminId,
        proposedValue: negotiation.proposedValue,
        message: negotiation.message,
        createdAt: DateTime.now(),
        isProviderProposal: negotiation.isProviderProposal,
        status: negotiation.status,
      );
      
      negotiations.add(newNegotiation);
      
      await _sharedPreferences.setString(_negotiationsKey, jsonEncode(negotiations.map((n) => n.toJson()).toList()));
      
      return newNegotiation;
    } catch (e) {
      throw Exception('Failed to create negotiation: $e');
    }
  }
  
  @override
  Future<CouponNegotiation> updateNegotiation(CouponNegotiation negotiation) async {
    try {
      // In a real app, we would update via API
      // final response = await _apiService.put('/coupon-negotiations/${negotiation.id}', body: negotiation.toJson());
      
      // For demo purposes, we'll use SharedPreferences
      final negotiationsJson = _sharedPreferences.getString(_negotiationsKey);
      List<CouponNegotiation> negotiations = [];
      
      if (negotiationsJson != null) {
        final List<dynamic> decodedList = jsonDecode(negotiationsJson);
        negotiations = decodedList.map((item) => CouponNegotiation.fromJson(item)).toList();
      }
      
      final index = negotiations.indexWhere((n) => n.id == negotiation.id);
      if (index == -1) {
        throw Exception('Negotiation not found');
      }
      
      negotiations[index] = negotiation;
      
      await _sharedPreferences.setString(_negotiationsKey, jsonEncode(negotiations.map((n) => n.toJson()).toList()));
      
      return negotiation;
    } catch (e) {
      throw Exception('Failed to update negotiation: $e');
    }
  }
}
