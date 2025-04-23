import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/coupon/coupon_bloc.dart';
import 'package:flutter_activity_app/bloc/coupon/coupon_event.dart';
import 'package:flutter_activity_app/bloc/coupon/coupon_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/coupon.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:intl/intl.dart';

class ProviderCouponsScreen extends StatefulWidget {
  final String providerId;
  final List<Activity> activities;

  const ProviderCouponsScreen({
    Key? key,
    required this.providerId,
    required this.activities,
  }) : super(key: key);

  @override
  State<ProviderCouponsScreen> createState() => _ProviderCouponsScreenState();
}

class _ProviderCouponsScreenState extends State<ProviderCouponsScreen> {
  late CouponBloc _couponBloc;
  
  @override
  void initState() {
    super.initState();
    _couponBloc = getIt<CouponBloc>();
    
    _couponBloc.add(LoadCouponsByProvider(widget.providerId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _couponBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Coupons & Discounts'),
        ),
        body: BlocBuilder<CouponBloc, CouponState>(
          builder: (context, state) {
            if (state is CouponLoading && state is! CouponsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            
            List<Coupon> coupons = [];
            if (state is CouponsLoaded) {
              coupons = state.coupons;
            }
            
            if (coupons.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Coupons Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin has not created any coupons for your activities',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Separate coupons into negotiable and non-negotiable
            final negotiableCoupons = coupons.where((c) => c.isNegotiable && !c.isApproved).toList();
            final approvedCoupons = coupons.where((c) => c.isApproved).toList();
            
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (negotiableCoupons.isNotEmpty) ...[
                  const Text(
                    'Pending Approval',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...negotiableCoupons.map((coupon) => _buildNegotiableCouponCard(coupon)),
                  const SizedBox(height: 24),
                ],
                if (approvedCoupons.isNotEmpty) ...[
                  const Text(
                    'Active Coupons',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...approvedCoupons.map((coupon) => _buildCouponCard(coupon)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildCouponCard(Coupon coupon) {
    final activity = widget.activities.firstWhere(
      (a) => a.id == coupon.activityId,
      orElse: () => Activity(
        id: '',
        name: 'Unknown Activity',
        category: '',
        location: '',
        price: 0,
        rating: 0,
        reviews: [],
        image: '',
        description: '',
        duration: '',
        includes: [],
        excludes: [],
        provider: Provider(
          id: '',
          name: '',
          rating: 0,
          verified: false,
          image: '',
          phone: '',
          email: '',
        ),
        images: [],
        latitude: 0,
        longitude: 0,
        availableDates: [],
        availableTimes: [],
        tags: [],
        requiresApproval: false,
      ),
    );
    
    final isValid = coupon.isValid;
    final statusColor = isValid ? Colors.green : Colors.red;
    final statusText = isValid ? 'Active' : 'Inactive';
    
    final discountText = coupon.type == CouponType.percentage
        ? '${coupon.value.toStringAsFixed(0)}% off'
        : '\$${coupon.value.toStringAsFixed(2)} off';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        discountText,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Valid: ${DateFormat('MMM d, y').format(coupon.validFrom)} - ${DateFormat('MMM d, y').format(coupon.validUntil)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.hiking, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Activity: ${activity.name}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (coupon.description != null && coupon.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.description, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Description: ${coupon.description}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNegotiableCouponCard(Coupon coupon) {
    final activity = widget.activities.firstWhere(
      (a) => a.id == coupon.activityId,
      orElse: () => Activity(
        id: '',
        name: 'Unknown Activity',
        category: '',
        location: '',
        price: 0,
        rating: 0,
        reviews: [],
        image: '',
        description: '',
        duration: '',
        includes: [],
        excludes: [],
        provider: Provider(
          id: '',
          name: '',
          rating: 0,
          verified: false,
          image: '',
          phone: '',
          email: '',
        ),
        images: [],
        latitude: 0,
        longitude: 0,
        availableDates: [],
        availableTimes: [],
        tags: [],
        requiresApproval: false,
      ),
    );
    
    final discountText = coupon.type == CouponType.percentage
        ? '${coupon.value.toStringAsFixed(0)}% off'
        : '\$${coupon.value.toStringAsFixed(2)} off';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            coupon.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Negotiable',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        discountText,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Valid: ${DateFormat('MMM d, y').format(coupon.validFrom)} - ${DateFormat('MMM d, y').format(coupon.validUntil)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.hiking, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Activity: ${activity.name}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (coupon.description != null && coupon.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.description, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Description: ${coupon.description}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'This coupon requires your approval. You can negotiate the terms.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _showNegotiationDialog(context, coupon);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Negotiate Terms'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showNegotiationDialog(BuildContext context, Coupon coupon) {
    final formKey = GlobalKey<FormState>();
    double proposedValue = coupon.value;
    String message = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Negotiate Coupon Terms'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current value: ${coupon.type == CouponType.percentage ? '${coupon.value.toStringAsFixed(0)}%' : '\$${coupon.value.toStringAsFixed(2)}'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Proposed Value',
                  hintText: coupon.type == CouponType.percentage 
                      ? 'e.g., 15 for 15%' 
                      : 'e.g., 5 for \$5',
                ),
                keyboardType: TextInputType.number,
                initialValue: proposedValue.toString(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onChanged: (val) {
                  proposedValue = double.tryParse(val) ?? proposedValue;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Message to Admin',
                  hintText: 'Explain your proposal',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
                onChanged: (val) {
                  message = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final negotiation = CouponNegotiation(
                  id: '',
                  couponId: coupon.id,
                  providerId: widget.providerId,
                  adminId: coupon.createdBy,
                  proposedValue: proposedValue,
                  message: message,
                  createdAt: DateTime.now(),
                  isProviderProposal: true,
                  status: 'pending',
                );
                
                _couponBloc.add(CreateNegotiation(negotiation));
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Negotiation proposal sent to admin'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Send Proposal'),
          ),
        ],
      ),
    );
  }
}
