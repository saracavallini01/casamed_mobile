import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingPage extends StatefulWidget {
  final int doctorId;
  final String doctorName;
  final String token;
  final bool isDoctor;
  final int userId; // Aggiungi il parametro userId

  const BookingPage({
    Key? key,
    required this.doctorId,
    required this.doctorName,
    required this.token,
    required this.isDoctor,
    required this.userId
  }) : super(key: key);

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late Future<List<Map<String, dynamic>>> _doctorAvailability;
  late Map<DateTime, List<Map<String, dynamic>>> _events;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _events = {};
    _doctorAvailability = _loadDoctorAvailability();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _createBooking(String date, String startTime, String endTime) async {
    final patientId = widget.userId; // ID del paziente (da ottenere secondo la tua logica)

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/bookings'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'doctorId': widget.doctorId,
          'patientId': patientId,
          'bookingDate': date,
          'startTime': startTime,
          'endTime': endTime,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prenotazione creata con successo!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante la creazione della prenotazione.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore di connessione.')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadDoctorAvailability() async {
    final availabilities = await ApiService(baseUrl: 'http://10.0.2.2:3000')
        .getDoctorAvailability(widget.doctorId, widget.token);

    setState(() {
      _events.clear(); // Pulisci gli eventi esistenti
      for (var availability in availabilities) {
        DateTime fullDateTime = DateTime.parse(availability['date']).toLocal();
        DateTime date = _normalizeDate(fullDateTime);

        String timeRange = '${availability['start_time']} - ${availability['end_time']}';

        if (_events.containsKey(date)) {
          _events[date]?.add({
            'timeRange': timeRange,
            'date': availability['date'],
            'start_time': availability['start_time'],
            'end_time': availability['end_time'],
          });
        } else {
          _events[date] = [{
            'timeRange': timeRange,
            'date': availability['date'],
            'start_time': availability['start_time'],
            'end_time': availability['end_time'],
          }];
        }
      }
    });

    return availabilities;
  }



  Future<void> _deleteAvailability(String date, String startTime, String endTime) async {
    if (widget.isDoctor) {
      try {
        await ApiService(baseUrl: 'http://10.0.2.2:3000').deleteAvailability(
          widget.doctorId,
          widget.token,
          date,
          startTime,
          endTime,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disponibilità eliminata con successo!')),
        );

        // Ricarica la disponibilità
        await _loadDoctorAvailability(); // Carica le disponibilità aggiornate
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante l\'eliminazione della disponibilità.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorName),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _doctorAvailability,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 10, 16),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) => _events[_normalizeDate(day)] ?? [],
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: _buildAvailabilityList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvailabilityList() {
    final dayEvents = _events[_normalizeDate(_selectedDay)] ?? [];

    if (dayEvents.isEmpty) {
      return const Center(child: Text('No availabilities on this day.'));
    }

    return ListView.builder(
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];

        return ListTile(
          title: Text(event['timeRange']),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isDoctor)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Conferma eliminazione'),
                        content: const Text('Sei sicuro di voler eliminare questa disponibilità?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annulla'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Elimina'),
                          ),
                        ],
                      ),
                    );

                    if (confirm) {
                      await _deleteAvailability(event['date'], event['start_time'], event['end_time']);
                      await _loadDoctorAvailability();
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.green),
                onPressed: () {
                  _createBooking(event['date'], event['start_time'], event['end_time']);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}