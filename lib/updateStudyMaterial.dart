import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/storage_service.dart';
import 'services/study_material_service.dart';
import 'theme.dart';

class UpdateStudyMaterialPage extends StatefulWidget {
  const UpdateStudyMaterialPage({super.key});

  @override
  State<UpdateStudyMaterialPage> createState() =>
      _UpdateStudyMaterialPageState();
}

class _UpdateStudyMaterialPageState extends State<UpdateStudyMaterialPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int _selectedStandard = 10;
  String _selectedSubject = 'Mathematics';
  File? _selectedFile;
  String? _selectedFileName;

  bool _isUploading = false;
  bool _isLoadingMaterials = true;

  List<Map<String, dynamic>> _allMaterials = [];
  String _searchQuery = '';
  String _selectedStandardFilter = 'All';

  final List<int> _availableStandards = [5, 6, 7, 8, 9, 10];
  final List<String> _availableSubjects = [
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
    _fetchMaterials();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMaterials() async {
    setState(() => _isLoadingMaterials = true);
    try {
      final data = await StudyMaterialService.instance.getAllStudyMaterials();
      if (mounted) {
        setState(() {
          _allMaterials = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching study materials: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMaterials = false);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          setState(() {
            _selectedFile = File(path);
            _selectedFileName = result.files.first.name;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      _showSnackBar('Failed to select file', Colors.red);
    }
  }

  Future<void> _uploadStudyMaterial() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('Please enter a material title', Colors.amber[800]!);
      return;
    }

    if (_selectedFile == null) {
      _showSnackBar('Please attach a document or PDF file', Colors.amber[800]!);
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Upload file to Supabase Storage bucket 'study-materials'
      final storagePath = await StorageService.instance.uploadStudyMaterial(
        standard: _selectedStandard,
        subject: _selectedSubject,
        file: _selectedFile!,
      );

      // 2. Insert record into Supabase 'study_materials' table (triggers push notification)
      await StudyMaterialService.instance.addStudyMaterial(
        standard: _selectedStandard,
        subject: _selectedSubject,
        title: title,
        filePath: storagePath,
      );

      if (mounted) {
        _showSnackBar('Study material uploaded & class notified! 📚', const Color(0xFF10B981));
        _titleController.clear();
        setState(() {
          _selectedFile = null;
          _selectedFileName = null;
        });
        _fetchMaterials();
      }
    } catch (e) {
      debugPrint('Error uploading study material: $e');
      if (mounted) {
        _showSnackBar('Upload failed: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteMaterial(Map<String, dynamic> item) async {
    final materialId = item['id']?.toString() ?? '';
    final title = item['title'] as String? ?? 'this material';
    final filePath = item['file_path'] as String? ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Material', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$title"? This will remove the file permanently.', style: GoogleFonts.outfit()),
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

    try {
      // Delete storage file from bucket
      if (filePath.isNotEmpty) {
        await StorageService.instance.deleteStudyMaterial(filePath);
      }
      // Delete DB record
      await StudyMaterialService.instance.deleteStudyMaterial(materialId);

      if (mounted) {
        _showSnackBar('Material deleted successfully', Colors.red);
        _fetchMaterials();
      }
    } catch (e) {
      debugPrint('Error deleting material: $e');
      if (mounted) {
        _showSnackBar('Delete failed: $e', Colors.red);
      }
    }
  }

  void _showEditMaterialDialog(Map<String, dynamic> item) {
    final materialId = item['id']?.toString() ?? '';
    final currentTitle = item['title'] as String? ?? '';
    final currentSubject = item['subject'] as String? ?? 'Mathematics';
    final currentStandard = item['standard'] is int ? item['standard'] as int : 10;
    final currentFilePath = item['file_path'] as String? ?? '';

    final editTitleController = TextEditingController(text: currentTitle);
    int editStd = currentStandard;
    String editSubject = _availableSubjects.contains(currentSubject) ? currentSubject : _availableSubjects.first;
    File? editFile;
    String? editFileName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Edit Study Material', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Standard Class', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: editStd,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _availableStandards.map((std) {
                        return DropdownMenuItem(value: std, child: Text('Std $std', style: GoogleFonts.outfit(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => editStd = val ?? editStd),
                    ),
                    const SizedBox(height: 14),

                    Text('Subject', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: editSubject,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _availableSubjects.map((sub) {
                        return DropdownMenuItem(value: sub, child: Text(sub, style: GoogleFonts.outfit(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => editSubject = val ?? editSubject),
                    ),
                    const SizedBox(height: 14),

                    Text('Title', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: editTitleController,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('Replace File (Optional)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles();
                        if (res != null && res.files.isNotEmpty && res.files.first.path != null) {
                          setDialogState(() {
                            editFile = File(res.files.first.path!);
                            editFileName = res.files.first.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file_rounded, size: 18),
                      label: Text(
                        editFileName ?? 'Choose Replacement File',
                        style: GoogleFonts.outfit(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  onPressed: () async {
                    final newTitle = editTitleController.text.trim();
                    if (newTitle.isEmpty) return;

                    String? newStoragePath;
                    if (editFile != null) {
                      // Upload replacement file
                      newStoragePath = await StorageService.instance.uploadStudyMaterial(
                        standard: editStd,
                        subject: editSubject,
                        file: editFile!,
                      );
                      // Delete old storage file if replaced
                      if (currentFilePath.isNotEmpty) {
                        try {
                          await StorageService.instance.deleteStudyMaterial(currentFilePath);
                        } catch (_) {}
                      }
                    }

                    await StudyMaterialService.instance.updateStudyMaterial(
                      materialId: materialId,
                      standard: editStd,
                      subject: editSubject,
                      title: newTitle,
                      filePath: newStoragePath,
                    );

                    if (mounted) {
                      _showSnackBar('Study material updated!', const Color(0xFF10B981));
                      _fetchMaterials();
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text('Save Changes', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openFileUrl(String filePath) async {
    if (filePath.isEmpty) return;
    final publicUrl = StorageService.instance.getStudyMaterialUrl(filePath);
    final uri = Uri.parse(publicUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open file URL', Colors.red);
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Study Material Hub',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchMaterials,
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textLight,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(icon: Icon(Icons.cloud_upload_rounded), text: 'Upload Material'),
              Tab(icon: Icon(Icons.folder_copy_rounded), text: 'Manage Materials'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUploadTab(),
            _buildManageTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
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
                    Icons.menu_book_rounded,
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
                        'Upload Study Resource',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Upload notes, PDFs, and assignments stored in Supabase "study-materials" bucket.',
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

          // Standard & Subject Pickers Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Standard',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedStandard,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryColor),
                          items: _availableStandards.map((std) {
                            return DropdownMenuItem(
                              value: std,
                              child: Text('Std $std', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStandard = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSubject,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryColor),
                          items: _availableSubjects.map((sub) {
                            return DropdownMenuItem(
                              value: sub,
                              child: Text(sub, style: GoogleFonts.outfit(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSubject = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title Input Field
          Text(
            'Material Title',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: GoogleFonts.outfit(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g. Chapter 4 Notes & Solutions',
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

          // Select File Button & Card
          Text(
            'Attachment File (PDF, Document, Image)',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _selectedFile != null ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: _selectedFile != null ? 2 : 1,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null ? Icons.picture_as_pdf_rounded : Icons.cloud_upload_outlined,
                    size: 42,
                    color: _selectedFile != null ? AppTheme.primaryColor : Colors.grey[400],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedFileName ?? 'Tap to browse and select file',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.normal,
                      color: _selectedFile != null ? AppTheme.textDark : AppTheme.textLight,
                      fontSize: 14,
                    ),
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ready to upload to Supabase',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Submit Upload Button
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
                elevation: 3,
              ),
              onPressed: _isUploading ? null : _uploadStudyMaterial,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(
                _isUploading ? 'Uploading to Supabase...' : 'Upload & Notify Class',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageTab() {
    if (_isLoadingMaterials) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _allMaterials.where((item) {
      final title = (item['title'] as String? ?? '').toLowerCase();
      final subject = (item['subject'] as String? ?? '').toLowerCase();
      final std = item['standard']?.toString() ?? '';

      final matchesQuery = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          subject.contains(_searchQuery.toLowerCase());

      bool matchesStd = true;
      if (_selectedStandardFilter != 'All') {
        matchesStd = std == _selectedStandardFilter;
      }

      return matchesQuery && matchesStd;
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchMaterials,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search materials by title or subject...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Class Standard Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['All', '5', '6', '7', '8', '9', '10'].map((stdStr) {
                  final isSelected = _selectedStandardFilter == stdStr;
                  final label = stdStr == 'All' ? 'All Classes' : 'Std $stdStr';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.outfit(
                        color: isSelected ? Colors.white : AppTheme.textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedStandardFilter = stdStr;
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
            const SizedBox(height: 16),

            // Materials List
            if (filtered.isEmpty)
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
                    Icon(Icons.folder_off_rounded, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No Study Materials Found',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try adjusting your search query or standard class filter.',
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
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final title = item['title'] as String? ?? 'Untitled';
                  final subject = item['subject'] as String? ?? 'General';
                  final std = item['standard']?.toString() ?? 'N/A';
                  final filePath = item['file_path'] as String? ?? '';
                  final uploadedAt = item['uploaded_at']?.toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.softShadow,
                      border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Std $std',
                                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          subject,
                                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    title,
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                  ),
                                ],
                              ),
                            ),

                            // Action Buttons
                            IconButton(
                              icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.primaryColor, size: 20),
                              onPressed: () => _openFileUrl(filePath),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                              onPressed: () => _showEditMaterialDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: () => _deleteMaterial(item),
                            ),
                          ],
                        ),
                        if (uploadedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Uploaded: ${_formatDateTime(uploadedAt)}',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textLight),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
