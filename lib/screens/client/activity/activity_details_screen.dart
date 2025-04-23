import 'package:flutter/material.dart';
import 'package:flutter_activity_app/screens/client/reservation/reservation_form_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_event.dart';
import 'package:flutter_activity_app/bloc/activity/activity_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/widgets/network_error_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailsScreen({
    Key? key,
    required this.activityId,
  }) : super(key: key);

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_profile') ?? '';
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show floating button only when scrolling down
    if (_scrollController.offset > 200 && !_showFloatingButton) {
      setState(() {
        _showFloatingButton = true;
      });
    } else if (_scrollController.offset <= 200 && _showFloatingButton) {
      setState(() {
        _showFloatingButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ActivityBloc>()..add(LoadActivityDetails(widget.activityId)),
      child: Scaffold(
        floatingActionButton: BlocBuilder<ActivityBloc, ActivityState>(
          builder: (context, state) {
            if (state is ActivityDetailsLoaded && _showFloatingButton) {
              return FloatingActionButton(
                onPressed: () {
                  // Navigate to booking screen with activityId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservationFormScreen(
                        activityId: widget.activityId,
                        userId: _userId,
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.book_online),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        body: BlocBuilder<ActivityBloc, ActivityState>(
          builder: (context, state) {
            if (state is ActivityLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ActivityDetailsLoaded) {
              return _buildActivityDetails(context, state.activity);
            } else if (state is ActivityError) {
              return NetworkErrorWidget(
                message: 'Could not load activity details',
                onRetry: () {
                  context
                      .read<ActivityBloc>()
                      .add(LoadActivityDetails(widget.activityId));
                },
              );
            } else {
              return const Center(child: Text('Something went wrong'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildActivityDetails(BuildContext context, Activity activity) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildAppBar(context, activity),
        SliverToBoxAdapter(
          child: _buildContent(context, activity),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, Activity activity) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              activity.image,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        BlocBuilder<ActivityBloc, ActivityState>(
          builder: (context, state) {
            if (state is ActivityDetailsLoaded) {
              return IconButton(
                icon: Icon(
                  state.activity.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: state.activity.isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  context.read<ActivityBloc>().add(ToggleFavorite(activity.id!));
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share functionality coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, Activity activity) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, activity),
          const SizedBox(height: 24),

          // Description with "Read more" functionality
          _buildExpandableDescription(activity),
          const SizedBox(height: 24),

          // Use cards to organize content
          _buildDetailsCard(activity),
          const SizedBox(height: 16),
          _buildIncludesCard(activity),
          const SizedBox(height: 16),
          _buildProviderCard(activity),
          const SizedBox(height: 32),

          // Only show the button at the bottom when not scrolled
          BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) {
              if (state is ActivityDetailsLoaded && !_showFloatingButton) {
                return _buildBookButton(context);
              }
              return const SizedBox(height: 60); // Space for FAB
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Activity activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                activity.location,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    activity.rating.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandableDescription(Activity activity) {
    return ExpandableText(
      text: activity.description,
      maxLines: 3,
    );
  }

  Widget _buildDetailsCard(Activity activity) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailItem(Icons.category, activity.category),
                _buildDetailItem(Icons.access_time, activity.duration),
                _buildDetailItem(Icons.attach_money,
                    '\$${activity.price.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIncludesCard(Activity activity) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What\'s Included',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...activity.includes.map((item) => _buildListItem(item, true)),
            if (activity.excludes.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'What\'s Not Included',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...activity.excludes.map((item) => _buildListItem(item, false)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String text, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isIncluded ? Icons.check_circle : Icons.cancel,
            color: isIncluded ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(Activity activity) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: activity.provider.image.isNotEmpty
                      ? AssetImage(activity.provider.image)
                      : null,
                  radius: 24,
                  child: activity.provider.image.isEmpty
                      ? Text(activity.provider.name.isNotEmpty
                          ? activity.provider.name[0]
                          : '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.provider.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (activity.provider.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${activity.provider.rating}'),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              // Show provider details
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('View Profile'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to booking screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReservationFormScreen(
                activityId: widget.activityId,
                userId: _userId,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Book Now',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Custom expandable text widget
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableText({
    Key? key,
    required this.text,
    this.maxLines = 3,
  }) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            widget.text,
            style: const TextStyle(fontSize: 16, height: 1.5),
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(
            widget.text,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _expanded ? 'Read less' : 'Read more',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }
}
