import 'package:doctor_app/features/appointment/model/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Appointment.fromJson', () {
    test('parses Django AppointmentSerializer payload', () {
      final item = Appointment.fromJson({
        'id': 7,
        'patient_id': 'P-2026-HKG',
        'patient_name': '황현경',
        'doctor_id': 'DOC-001',
        'doctor_name': '김순환',
        'department': '순환기내과',
        'scheduled_at': '2026-08-10T01:00:00Z',
        'status': 'requested',
        'memo': '흉통',
        'created_at': '2026-08-05T10:00:00Z',
        'updated_at': '2026-08-05T10:00:00Z',
      });

      expect(item.id, '7');
      expect(item.patientId, 'P-2026-HKG');
      expect(item.patientName, '황현경');
      expect(item.doctorId, 'DOC-001');
      expect(item.status, AppointmentStatus.requested);
      expect(item.canConfirm, isTrue);
      expect(item.canCancel, isTrue);
      expect(item.canComplete, isFalse);
    });
  });
}
