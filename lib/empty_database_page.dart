import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/profile_service.dart';
import 'theme.dart';

class EmptyDatabasePage extends StatefulWidget {
  const EmptyDatabasePage({super.key});

  @override
  State<EmptyDatabasePage> createState() => _EmptyDatabasePageState();
}

class _EmptyDatabasePageState extends State<EmptyDatabasePage> {
  bool _isLoading = true;
  bool _isDeleting = false;
  List<Map<String, dynamic>> _students = [];
  final Set<String> _selectedStudentIds = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await ProfileService.instance.getAllProfiles();
      if (mounted) {
        setState(() {
          _students = profiles;
          _selectedStudentIds.clear();
          _selectAll = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students for reset: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSelectedStudents() async {
    if (_selectedStudentIds.isEmpty) {
      _showSnackBar('Please select at least one student profile to delete.', Colors.amber[800]!);
      return;
    }

    final count = _selectedStudentIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Student Profiles', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete $count selected student profile(s) from Supabase?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      for (final id in _selectedStudentIds) {
        await ProfileService.instance.deleteProfile(id);
      }

      if (mounted) {
        _showSnackBar('$count student profile(s) deleted successfully.', Colors.red);
        _fetchStudents();
      }
    } catch (e) {
      debugPrint('Error deleting students: $e');
      if (mounted) {
        _showSnackBar('Error deleting profiles: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage & Reset Students',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchStudents,
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
                    'Loading student records...',
                    style: GoogleFonts.outfit(color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Top Controls Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: AppTheme.primaryColor,
                          value: _selectAll,
                          onChanged: (bool? value) {
                            setState(() {
                              _selectAll = value ?? false;
                              if (_selectAll) {
                                _selectedStudentIds.addAll(_students.map((s) => s['id']?.toString() ?? ''));
                              } else {
                                _selectedStudentIds.clear();
                              }
                            });
                          },
                        ),
                        Text(
                          'Select All (${_students.length})',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: _isDeleting || _selectedStudentIds.isEmpty ? null : _deleteSelectedStudents,
                          icon: _isDeleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_sweep_rounded, size: 18),
                          label: Text(
                            _isDeleting ? 'Deleting...' : 'Delete Selected (${_selectedStudentIds.length})',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Student Profiles List
                  Expanded(
                    child: _students.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline_rounded, size: 50, color: Colors.grey[350]),
                                const SizedBox(height: 12),
                                Text(
                                  'Database Reset Complete',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No active student profiles currently in Supabase.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textLight),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final id = student['id']?.toString() ?? '';
                              final name = student['name'] as String? ?? 'Student';
                              final std = (student['standard'] ?? student['std'])?.toString() ?? 'N/A';
                              final avatar = student['image_url'] as String?;
                              final isSelected = _selectedStudentIds.contains(id);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: AppTheme.softShadow,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.red.withValues(alpha: 0.5)
                                        : AppTheme.primaryLight.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    activeColor: Colors.red,
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedStudentIds.add(id);
                                        } else {
                                          _selectedStudentIds.remove(id);
                                        }
                                        _selectAll = _selectedStudentIds.length == _students.length;
                                      });
                                    },
                                  ),
                                  title: Text(
                                    name,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                                  ),
                                  subtitle: Text(
                                    'Class Std $std',
                                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight),
                                  ),
                                  trailing: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                    child: avatar == null
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 12),
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
