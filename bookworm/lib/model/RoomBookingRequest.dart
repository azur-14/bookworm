class RoomBookingRequest {
  final String id;
  final String userId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final String purpose;
  final DateTime requestTime;

  RoomBookingRequest({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    this.status = 'pending',
    required this.purpose,
    required this.requestTime,
  });

  factory RoomBookingRequest.fromJson(Map<String, dynamic> json) {
    return RoomBookingRequest(
      id: json['id'],
      userId: json['user_id'] is Map ? json['user_id']['_id'] : json['user_id'],
      roomId: json['room_id'] is Map ? json['room_id']['_id'] : json['room_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'],
      purpose: json['purpose'],
      requestTime: DateTime.parse(json['request_time']),
    );
  }
}
