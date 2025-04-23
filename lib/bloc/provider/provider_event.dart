import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/activity.dart';

abstract class ProviderEvent extends Equatable {
  const ProviderEvent();

  @override
  List<Object?> get props => [];
}

class LoadProviderActivities extends ProviderEvent {
  final String providerId;

  const LoadProviderActivities(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

class CreateActivity extends ProviderEvent {
  final Activity activity;

  const CreateActivity(this.activity);

  @override
  List<Object?> get props => [activity];
}

class UpdateActivity extends ProviderEvent {
  final Activity activity;

  const UpdateActivity(this.activity);

  @override
  List<Object?> get props => [activity];
}

class DeleteActivity extends ProviderEvent {
  final String activityId;

  const DeleteActivity(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class UpdateAvailability extends ProviderEvent {
  final String activityId;
  final List<AvailableDate> dates;
  final List<AvailableTime> times;

  const UpdateAvailability(this.activityId, this.dates, this.times);

  @override
  List<Object?> get props => [activityId, dates, times];
}
