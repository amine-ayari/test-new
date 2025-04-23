// TODO Implement this library.import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/user/user_bloc.dart';
import 'package:flutter_activity_app/bloc/user/user_event.dart';
import 'package:flutter_activity_app/bloc/user/user_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/widgets/activity_card.dart';

class FavoritesScreen extends StatefulWidget {
  final User user;

  const FavoritesScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late UserBloc _userBloc;

  @override
  void initState() {
    super.initState();
    _userBloc = getIt<UserBloc>();
    _userBloc.add(LoadFavoriteActivities(widget.user.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Activities'),
        elevation: 0,
      ),
      body: BlocProvider.value(
        value: _userBloc,
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is FavoritesLoaded) {
              return _buildFavoritesList(state.favorites);
            } else if (state is UserError) {
              return Center(
                child: Text('Error: ${state.message}'),
              );
            } else {
              return const Center(
                child: Text('No favorites found'),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<Activity> favorites) {
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No favorite activities yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Activities you mark as favorite will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final activity = favorites[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ActivityCard(
            activity: activity,
            onTap: () {
              // Navigate to activity details
            },
            onFavoriteToggle: () {
              // Toggle favorite status
              _userBloc.add(RemoveFavoriteActivity(widget.user.id, activity.id!));
            },
          ),
        );
      },
    );
  }
}
