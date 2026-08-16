import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/profile_service.dart';
import 'services/storage_service.dart';
import 'services/study_material_service.dart';
import 'theme.dart';

class StudentStudyMaterialPage extends StatefulWidget {
  const StudentStudyMaterialPage({super.key});

  @override
  State<StudentStudyMaterialPage> createState() =>
      _StudentStudyMaterialPageState();
}

class _StudentStudyMaterialPageState extends State<StudentStudyMaterialPage> {
  int _selectedStandard = 10;
  String _selectedSubjectFilter = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _materials = [];
  Timer? _pollingTimer;

  final List<int> _availableStandards = [5, 6, 7, 8, 9, 10];
  final List<String> _availableSubjects = [
    'All',
    'Mathematics',
    'Science',
    'English',
    'Social Science',
    'Gujarati',
    'Hindi',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchMaterials(isAutoPoll: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final profile = await ProfileService.instance.getCurrentProfile();
      if (profile != null) {
        final stdRaw = profile['standard'] ?? profile['std'];
        if (stdRaw != null) {
          final stdParsed = int.tryParse(stdRaw.toString());
          if (stdParsed != null && _availableStandards.contains(stdParsed)) {
            _selectedStandard = stdParsed;
          }
        }
      }
    } catch (_) {}

    await _fetchMaterials();
  }

  Future<void> _fetchMaterials({bool isAutoPoll = false}) async {
    if (!isAutoPoll) {
      setState(() => _isLoading = true);
    }
    try {
      final data = await StudyMaterialService.instance
          .getStudyMaterialsByStandard(_selectedStandard);
      if (mounted) {
        setState(() {
          _materials = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching study materials for student: $e');
    } finally {
      if (mounted && !isAutoPoll) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openFileUrl(String filePath) async {
    if (filePath.isEmpty) return;
    final publicUrl = StorageService.instance.getStudyMaterialUrl(filePath);
    final uri = Uri.parse(publicUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open document URL', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error opening file: $e', Colors.red);
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

  String _formatDateTime(String? rawIso) {
    if (rawIso == null) return '';
    try {
      final dt = DateTime.parse(rawIso).toLocal();
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${monthNames[dt.month - 1]}, $hour:$minute $amPm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMaterials = _materials.where((item) {
      if (_selectedSubjectFilter == 'All') return true;
      final subject = item['subject'] as String? ?? '';
      return subject.toLowerCase() == _selectedSubjectFilter.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Study Materials & Notes',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _fetchMaterials(),
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
                    'Loading study resources...',
                    style: GoogleFonts.outfit(color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchMaterials(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                              Icons.folder_special_rounded,
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
                                  'Class Study Resources',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Access chapter notes, worksheets, and reference guides for Std $_selectedStandard.',
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
                    const SizedBox(height: 20),

                    // Standard Chips Filter
                    Text(
                      'Select Class Standard',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _availableStandards.map((std) {
                          final isSelected = _selectedStandard == std;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text('Std $std'),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor,
                              backgroundColor: Colors.white,
                              labelStyle: GoogleFonts.outfit(
                                color: isSelected ? Colors.white : AppTheme.textDark,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStandard = std;
                                  });
                                  _fetchMaterials();
                                }
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subject Chips Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _availableSubjects.map((sub) {
                          final isSelected = _selectedSubjectFilter == sub;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(sub),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.8),
                              backgroundColor: Colors.white,
                              labelStyle: GoogleFonts.outfit(
                                color: isSelected ? Colors.white : AppTheme.textDark,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSubjectFilter = sub;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Materials List Header
                    Text(
                      'Available Resources (Std $_selectedStandard)',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),

                    if (filteredMaterials.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.auto_stories_rounded, size: 50, color: Colors.grey[350]),
                            const SizedBox(height: 12),
                            Text(
                              'No Materials Uploaded Yet',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Study materials for Std $_selectedStandard will appear here as soon as Sanjay Sir uploads them.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredMaterials.length,
                        itemBuilder: (context, index) {
                          final item = filteredMaterials[index];
                          final title = item['title'] as String? ?? 'Untitled Note';
                          final subject = item['subject'] as String? ?? 'General';
                          final filePath = item['file_path'] as String? ?? '';
                          final uploadedAt = item['uploaded_at']?.toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: AppTheme.softShadow,
                              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryColor, size: 24),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      subject,
                                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: uploadedAt != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Uploaded: ${_formatDateTime(uploadedAt)}',
                                        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textLight),
                                      ),
                                    )
                                  : null,
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () => _openFileUrl(filePath),
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: Text('Open', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
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
