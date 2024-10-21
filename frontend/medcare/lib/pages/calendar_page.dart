import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http; // Importa il pacchetto http
import 'dart:convert'; // Import per la codifica in JSON

class CalendarPage extends StatefulWidget {
  final int userId; // Aggiungi il parametro User ID
  final String token; // Aggiungi il parametro Token

  CalendarPage({required this.userId, required this.token});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Variabili per memorizzare la selezione dell'orario
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Set per memorizzare i giorni selezionati
  Set<DateTime> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleziona Disponibilità'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 10, 16),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _selectedDays.contains(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;

                if (_selectedDays.contains(selectedDay)) {
                  _selectedDays.remove(selectedDay); // Deseleziona la data
                } else {
                  _selectedDays.add(selectedDay); // Aggiungi la data
                }
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          SizedBox(height: 20),
          _buildTimeSelector(), // Costruzione dei selettori di orario
          ElevatedButton(
            onPressed: _saveAvailability,
            child: Text('Salva Disponibilità'),
          ),
        ],
      ),
    );
  }

  // Funzione per selezionare l'orario di inizio
  Future<void> _selectStartTime(BuildContext context) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      setState(() {
        _startTime = selectedTime;
      });
    }
  }

  // Funzione per selezionare l'orario di fine
  Future<void> _selectEndTime(BuildContext context) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      setState(() {
        _endTime = selectedTime;
      });
    }
  }

  // Funzione per costruire la parte dell'interfaccia che seleziona orari
  Widget _buildTimeSelector() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Orario di inizio: '),
            _startTime == null
                ? Text('Non selezionato')
                : Text('${_startTime!.hour}:${_startTime!.minute}'),
            TextButton(
              onPressed: () => _selectStartTime(context),
              child: Text('Seleziona Inizio'),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Orario di fine: '),
            _endTime == null
                ? Text('Non selezionato')
                : Text('${_endTime!.hour}:${_endTime!.minute}'),
            TextButton(
              onPressed: () => _selectEndTime(context),
              child: Text('Seleziona Fine'),
            ),
          ],
        ),
      ],
    );
  }

  // Funzione per salvare la disponibilità e inviarla al backend
  Future<void> _saveAvailability() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleziona un orario di inizio e fine')),
      );
      return;
    }

    // Converti i giorni selezionati e gli orari in una lista
    List<Map<String, dynamic>> availabilityData = _selectedDays.map((day) {
      return {
        'date': day.toIso8601String(),
        'start_time': '${_startTime!.hour}:${_startTime!.minute}',
        'end_time': '${_endTime!.hour}:${_endTime!.minute}',
      };
    }).toList();

    // URL per inviare la richiesta (sostituisci con l'indirizzo del tuo backend)
    final url = Uri.parse('http://10.0.2.2:3000/calendar/${widget.userId}');

    try {
      // Invio della richiesta POST per salvare la disponibilità
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // Token per l'autenticazione
        },
        body: jsonEncode({'availability': availabilityData}), // Dati in formato JSON
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disponibilità salvata con successo!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il salvataggio.')),
        );
      }
    } catch (e) {
      print('Errore nella richiesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Si è verificato un errore.')),
      );
    }
  }
}






/*import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // Import for JSON encoding

class CalendarPage extends StatefulWidget {
  final int userId; // Add the User ID parameter
  final String token; // Add the Token parameter

  // Constructor to accept userId and token
  CalendarPage({required this.userId, required this.token});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Per memorizzare le date selezionate (disponibilità settimanale)
  Set<DateTime> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleziona Disponibilità')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 10, 16),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _selectedDays.contains(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;

                if (_selectedDays.contains(selectedDay)) {
                  _selectedDays.remove(selectedDay); // Deseleziona la data
                } else {
                  _selectedDays.add(selectedDay); // Aggiungi la data
                }
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          ElevatedButton(
            onPressed: _saveAvailability,
            child: Text('Salva Disponibilità'),
          ),
        ],
      ),
    );
  }

  // Funzione per salvare la disponibilità e inviarla al backend
  Future<void> _saveAvailability() async {
    // Convert the selected dates to a list of ISO8601 strings
    List<String> selectedDates = _selectedDays.map((day) => day.toIso8601String()).toList();

    // URL to send the request (replace with your backend address)
    final url = Uri.parse('http://10.0.2.2:3000/calendar/${widget.userId}');

    try {
      // Sending POST request to save availability
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // Add token for authentication
        },
        body: jsonEncode({'availability': selectedDates}), // Convert selected dates to JSON
      );

      if (response.statusCode == 200) {
        print('Disponibilità salvata con successo!');
        // Show a confirmation message using SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Disponibilità salvata con successo!'))
        );
      } else {
        print('Errore durante il salvataggio: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante il salvataggio.'))
        );
      }
    } catch (e) {
      print('Errore nella richiesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Si è verificato un errore.'))
      );
    }
  }
}*/

