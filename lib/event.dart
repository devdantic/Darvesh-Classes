import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/event_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingEvents = true;

  String _selectedCategory = 'Holiday';
  final Map<String, Map<String, dynamic>> _categories = {
    'Holiday': {'icon': Icons.beach_access_rounded, 'color': Colors.orange[700]!},
    'Test': {'icon': Icons.assignment_turned_in_rounded, 'color': Colors.red[600]!},
    'Exam': {'icon': Icons.school_rounded, 'color': Colors.purple[600]!},
    'Notice': {'icon': Icons.campaign_rounded, 'color': Colors.teal[600]!},
  };

  List<Map<String, dynamic>> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final events = await EventService.instance.getAllEvents();
      if (mounted) {
        setState(() {
          _recentEvents = events;
        });
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      _showSnackBar('Please enter both title and description.', Colors.amber[800]!);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Add event to Supabase
      await EventService.instance.addEvent(
        title: title,
        date: _selectedDate,
        description: description,
        category: _selectedCategory,
      );

      // 2. Broadcast push notification to all students
      final formattedDate = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
      final categoryEmoji = _selectedCategory == 'Holiday'
          ? '🌴'
          : _selectedCategory == 'Test'
              ? '📝'
              : _selectedCategory == 'Exam'
                  ? '🎓'
                  : '📢';

      await NotificationService.instance.sendTopicNotification(
        topic: 'all_students',
        title: '$categoryEmoji New Event ($formattedDate): $title',
        body: description,
        data: {'type': 'event'},
      );

      if (mounted) {
        _showSnackBar('Event saved & push notification sent to all students! 🎉', const Color(0xFF10B981));
        _titleController.clear();
        _descriptionController.clear();
        _fetchEvents();
      }
    } catch (e) {
      debugPrint('Error adding event: $e');
      if (mounted) {
        _showSnackBar('Failed to add event: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEvent(String id, String title) async {
    try {
      await EventService.instance.deleteEvent(id);
      if (mounted) {
        _showSnackBar('Event "$title" removed', Colors.red);
        _fetchEvents();
      }
    } catch (e) {
      debugPrint('Error deleting event: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDisplayDate(DateTime date) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekDays[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Add Calendar Event',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_note_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Event & Alert',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Add holidays, test dates, or exams. Broadcasts push notification automatically.',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Selector
              Text(
                'Event Category',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _categories.entries.map((entry) {
                  final catName = entry.key;
                  final catIcon = entry.value['icon'] as IconData;
                  final catColor = entry.value['color'] as Color;
                  final isSelected = _selectedCategory == catName;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = catName;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? catColor : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isSelected ? AppTheme.softShadow : null,
                          border: Border.all(
                            color: isSelected ? catColor : Colors.grey.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              catIcon,
                              color: isSelected ? Colors.white : catColor,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              catName,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Title Field
              Text(
                'Event Title',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                focusNode: _focusNode,
                style: GoogleFonts.outfit(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'e.g. Science Unit Test / Diwali Holiday',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date Selector Button Tile
              Text(
                'Event Date',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatDisplayDate(_selectedDate),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Text(
                        'Change',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description Text Box
              Text(
                'Description / Details',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                style: GoogleFonts.outfit(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter syllabus details, timing, or holiday instructions...',
                  alignLabelWithHint: true,
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Event Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _saveEvent,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.add_alert_rounded),
                  label: Text(
                    _isLoading ? 'Publishing Event...' : 'Publish Event & Notify All',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Recent Events Section
              Text(
                'Existing Events (${_recentEvents.length})',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoadingEvents)
                const Center(child: CircularProgressIndicator())
              else if (_recentEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'No events added yet.',
                      style: GoogleFonts.outfit(color: AppTheme.textLight),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentEvents.length,
                  itemBuilder: (context, index) {
                    final ev = _recentEvents[index];
                    final id = ev['id']?.toString() ?? '';
                    final title = ev['title'] as String? ?? 'Event';
                    final desc = ev['description'] as String? ?? '';
                    final dateVal = ev['date']?.toString() ?? '';
                    final cat = ev['category'] as String? ?? 'Notice';
                    final catColor = _categories[cat]?['color'] as Color? ?? AppTheme.primaryColor;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.softShadow,
                        border: Border.all(color: catColor.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _categories[cat]?['icon'] as IconData? ?? Icons.event,
                              color: catColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
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
                                        cat,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: catColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  desc,
                                  style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textLight),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '📅 $dateVal',
                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            onPressed: () => _deleteEvent(id, title),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

