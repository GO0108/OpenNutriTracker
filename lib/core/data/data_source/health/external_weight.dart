import 'package:equatable/equatable.dart';

/// One body-weight reading from the platform health store — on a Samsung
/// phone, whatever Samsung Health (a connected scale or a manual entry)
/// shared with Health Connect.
class ExternalWeight extends Equatable {
  final DateTime time;
  final double kg;

  const ExternalWeight({required this.time, required this.kg});

  @override
  List<Object?> get props => [time, kg];
}
