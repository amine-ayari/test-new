import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/activity.dart';

abstract class ProviderState extends Equatable {
  const ProviderState();

  @override
  List<Object?> get props => [];
}

class ProviderInitial extends ProviderState {
  const ProviderInitial();
}

class ProviderLoading extends ProviderState {
  const ProviderLoading();
}

class ProviderActivitiesLoaded extends ProviderState {
  final List<Activity> activities;

  const ProviderActivitiesLoaded(this.activities);

  @override
  List<Object?> get props => [activities];
}

class ActivityCreated extends ProviderState {
  final Activity activity;

  const ActivityCreated(this.activity);

  @override
  List<Object?> get props => [activity];
}

class ActivityUpdated extends ProviderState {
  final Activity activity;

  const ActivityUpdated(this.activity);

  @override
  List<Object?> get props => [activity];
}

class ActivityDeleted extends ProviderState {
  final String activityId;

  const ActivityDeleted(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class AvailabilityUpdated extends ProviderState {
  final String activityId;
  final List<AvailableDate> dates;
  final List<AvailableTime> times;

  const AvailabilityUpdated(this.activityId, this.dates, this.times);

  @override
  List<Object?> get props => [activityId, dates, times];
}

class ProviderError extends ProviderState {
  final String message;

  const ProviderError(this.message);

  @override
  List<Object?> get props => [message];
}
