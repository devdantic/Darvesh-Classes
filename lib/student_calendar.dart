import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'services/event_service.dart';
import 'theme.dart';

class StudentCalendarPage extends StatefulWidget {
  const StudentCalendarPage({super.key});

  @override
  State<StudentCalendarPage> createState() => _StudentCalendarPageState();
}

class _StudentCalendarPageState extends State<StudentCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  bool _isLoading = true;
  Map<DateTime, List<Event>> _eventsMap = {};
  List<Event> _selectedEvents = [];

  final Map<String, Map<String, dynamic>> _categories = {
    'Holiday': {'icon': Icons.beach_access_rounded, 'color': Colors.orange[700]!},
    'Test': {'icon': Icons.assignment_turned_in_rounded, 'color': Colors.red[600]!},
    'Exam': {'icon': Icons.school_rounded, 'color': Colors.purple[600]!},
    'Notice': {'icon': Icons.campaign_rounded, 'color': Colors.teal[600]!},
  };

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final rawEvents = await EventService.instance.getAllEvents();
      final Map<DateTime, List<Event>> tempMap = {};

      for (var item in rawEvents) {
        final dateVal = item['date']?.toString();
        if (dateVal != null) {
          final parts = dateVal.split('-');
          if (parts.length == 3) {
            final year = int.tryParse(parts[0]) ?? 2026;
            final month = int.tryParse(parts[1]) ?? 1;
            final day = int.tryParse(parts[2]) ?? 1;
            final dateKey = DateTime.utc(year, month, day);

            final eventObj = Event(
              title: item['title'] as String? ?? 'Event',
              description: item['description'] as String? ?? '',
              category: item['category'] as String? ?? 'Notice',
            );

            if (tempMap.containsKey(dateKey)) {
              tempMap[dateKey]!.add(eventObj);
            } else {
              tempMap[dateKey] = [eventObj];
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _eventsMap = tempMap;
          _selectedEvents = _getEventsForDay(_selectedDay);
        });
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final DateTime dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _eventsMap[dayUtc] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Important Dates & Events',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchEvents,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading calendar events...',
                    style: GoogleFonts.outfit(color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Calendar Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2022, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      eventLoader: (day) => _getEventsForDay(day),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: true,
                        formatButtonShowsNext: false,
                        formatButtonDecoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        formatButtonTextStyle: GoogleFonts.outfit(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        titleTextStyle: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
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
                  ),

                  // Events Header for Selected Date
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Events on ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_selectedEvents.length} Event(s)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Event List or Empty State
                  if (_selectedEvents.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_available_rounded, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                            'No events scheduled for this day.',
                            style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: _selectedEvents.map((event) {
                          final catColor = _categories[event.category]?['color'] as Color? ?? AppTheme.primaryColor;
                          final catIcon = _categories[event.category]?['icon'] as IconData? ?? Icons.event;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softShadow,
                              border: Border.all(color: catColor.withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(catIcon, color: catColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              event.title,
                                              style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: catColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              event.category,
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: catColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        event.description,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: AppTheme.textLight,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class Event {
  final String title;
  final String description;
  final String category;

  Event({
    required this.title,
    required this.description,
    required this.category,
  });
}

