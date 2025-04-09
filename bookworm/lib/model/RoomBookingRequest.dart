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

  factory RoomBookingRequest.fromMap(Map<String, dynamic> data) {
    return RoomBookingRequest(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      roomId: data['room_id'] as String,
      startTime: DateTime.parse(data['start_time'] as String),
      endTime: DateTime.parse(data['end_time'] as String),
      status: data['status'] as String,
      purpose: data['purpose'] as String,
      requestTime: DateTime.parse(data['request_time'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'room_id': roomId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'purpose': purpose,
      'request_time': requestTime.toIso8601String(),
    };
  }
}
