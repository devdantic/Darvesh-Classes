import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class StudentCalendarPage extends StatefulWidget {
  const StudentCalendarPage({Key? key}) : super(key: key);

  @override
  _StudentCalendarPageState createState() => _StudentCalendarPageState();
}

class _StudentCalendarPageState extends State<StudentCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  void dispos() {
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    try {
      final eventsSnapshot =
          await FirebaseFirestore.instance.collection('events').get();
      setState(() {
        _events = {
          for (var event in eventsSnapshot.docs)
            (event['date'] as Timestamp).toDate(): [
              Event(event['title'], event['description'])
            ]
        };
      });
    } catch (e) {
      //print('Error fetching events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Important Dates'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2101, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: (day) => _getEventsForDay(day),
            startingDayOfWeek: StartingDayOfWeek.sunday,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents = _getEventsForDay(selectedDay);
              });
            },
          ),
          if (_selectedEvents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var event in _selectedEvents) EventCard(event),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Event> _getEventsForDay(DateTime day) {
    final DateTime dayWithoutTime = DateTime(day.year, day.month, day.day);

    return _events[dayWithoutTime] ?? [];
  }
}

class Event {
  final String title;
  final String description;

  Event(this.title, this.description);
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard(this.event, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(event.description),
          ],
        ),
      ),
    );
  }
}
