import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import '../../models/contact.dart';
import '../../features/qr_code/services/qr_code_service.dart';
import '../../core/repositories/contact_repository.dart';
import '../../services/haptic_service.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';

/// Business card designer screen for creating custom digital cards
class BusinessCardDesignerScreen extends ConsumerStatefulWidget {
  final Contact? contact;

  const BusinessCardDesignerScreen({
    super.key,
    this.contact,
  });

  @override
  ConsumerState<BusinessCardDesignerScreen> createState() =>
      _BusinessCardDesignerScreenState();
}

class _BusinessCardDesignerScreenState
    extends ConsumerState<BusinessCardDesignerScreen> {
  final GlobalKey _cardKey = GlobalKey();
  final QrCodeService _qrCodeService = QrCodeService();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;

  // Design options
  int _selectedTemplate = 0;
  Color _primaryColor = QuantumTheme.primaryBlue;
  Color _accentColor = QuantumTheme.accentPurple;
  bool _includeQrCode = true;
  bool _includePhoto = false;

  final List<CardTemplate> _templates = [
    CardTemplate(
      name: 'Modern',
      layout: CardLayout.modern,
      gradient: const LinearGradient(
        colors: [QuantumTheme.primaryBlue, QuantumTheme.accentPurple],
      ),
    ),
    CardTemplate(
      name: 'Classic',
      layout: CardLayout.classic,
      gradient: const LinearGradient(
        colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
      ),
    ),
    CardTemplate(
      name: 'Elegant',
      layout: CardLayout.elegant,
      gradient: const LinearGradient(
        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      ),
    ),
    CardTemplate(
      name: 'Bold',
      layout: CardLayout.bold,
      gradient: const LinearGradient(
        colors: [QuantumTheme.secondaryPink, QuantumTheme.accentPurple],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController =
        TextEditingController(text: widget.contact?.fullName ?? '');
    _titleController = TextEditingController(text: widget.contact?.title ?? '');
    _companyController =
        TextEditingController(text: widget.contact?.company ?? '');
    _emailController = TextEditingController(
      text: widget.contact?.emails.isNotEmpty == true
          ? widget.contact!.emails.first.value
          : '',
    );
    _phoneController = TextEditingController(
      text: widget.contact?.phones.isNotEmpty == true
          ? widget.contact!.phones.first.value
          : '',
    );
    _websiteController =
        TextEditingController(text: widget.contact?.website ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureCardAsImage() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveCard() async {
    if (_nameController.text.isEmpty) {
      _showError('Please enter a name');
      return;
    }

    // Create or update contact
    final contact = widget.contact ?? Contact();
    contact
      ..fullName = _nameController.text
      ..title = _titleController.text.isNotEmpty ? _titleController.text : null
      ..company =
          _companyController.text.isNotEmpty ? _companyController.text : null
      ..website =
          _websiteController.text.isNotEmpty ? _websiteController.text : null
      ..updatedAt = DateTime.now();

    // Update email
    if (_emailController.text.isNotEmpty) {
      contact.emails = [
        EmailItem()
          ..value = _emailController.text
          ..confidence = 1.0
      ];
    }

    // Update phone
    if (_phoneController.text.isNotEmpty) {
      contact.phones = [
        PhoneItem()
          ..value = _phoneController.text
          ..confidence = 1.0
      ];
    }

    // Save to repository
    final repository = ref.read(contactRepositoryProvider);
    final result = await repository.save(contact);

    result.fold(
      (failure) => _showError('Failed to save: ${failure.message}'),
      (_) {
        HapticService().successImpact();
        _showSuccess('Business card saved successfully');
        if (mounted) {
          context.pop();
        }
      },
    );
  }

  Future<void> _exportCard() async {
    final imageBytes = await _captureCardAsImage();
    if (imageBytes == null) {
      _showError('Failed to export card');
      return;
    }

    // In a real implementation, you would save/share the image
    HapticService().successImpact();
    _showSuccess('Card exported successfully');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: QuantumTheme.errorRed,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: QuantumTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              QuantumTheme.deepSpace,
              QuantumTheme.darkPurple,
              QuantumTheme.deepSpace,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card preview
                      _buildCardPreview(),

                      const SizedBox(height: 32),

                      // Template selector
                      _buildTemplateSelector(),

                      const SizedBox(height: 32),

                      // Design options
                      _buildDesignOptions(),

                      const SizedBox(height: 32),

                      // Information fields
                      _buildInformationFields(),
                    ],
                  ),
                ),
              ),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Card Designer',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: _exportCard,
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    return Center(
      child: RepaintBoundary(
        key: _cardKey,
        child: _buildBusinessCard(),
      ),
    );
  }

  Widget _buildBusinessCard() {
    final template = _templates[_selectedTemplate];

    return Container(
      width: 350,
      height: 200,
      decoration: BoxDecoration(
        gradient: template.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: CardPatternPainter(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildCardContent(template.layout),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(CardLayout layout) {
    switch (layout) {
      case CardLayout.modern:
        return _buildModernLayout();
      case CardLayout.classic:
        return _buildClassicLayout();
      case CardLayout.elegant:
        return _buildElegantLayout();
      case CardLayout.bold:
        return _buildBoldLayout();
    }
  }

  Widget _buildModernLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _nameController.text.isNotEmpty ? _nameController.text : 'Your Name',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (_titleController.text.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _titleController.text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
        if (_companyController.text.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _companyController.text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
        const Spacer(),
        if (_emailController.text.isNotEmpty)
          _buildContactLine(Icons.email, _emailController.text),
        if (_phoneController.text.isNotEmpty)
          _buildContactLine(Icons.phone, _phoneController.text),
        if (_websiteController.text.isNotEmpty)
          _buildContactLine(Icons.language, _websiteController.text),
      ],
    );
  }

  Widget _buildClassicLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _nameController.text.isNotEmpty ? _nameController.text : 'Your Name',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (_titleController.text.isNotEmpty ||
            _companyController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            [_titleController.text, _companyController.text]
                .where((s) => s.isNotEmpty)
                .join(' • '),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_emailController.text.isNotEmpty ||
            _phoneController.text.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_emailController.text.isNotEmpty)
                _buildContactChip(Icons.email, _emailController.text),
              if (_emailController.text.isNotEmpty &&
                  _phoneController.text.isNotEmpty)
                const SizedBox(width: 8),
              if (_phoneController.text.isNotEmpty)
                _buildContactChip(Icons.phone, _phoneController.text),
            ],
          ),
      ],
    );
  }

  Widget _buildElegantLayout() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _nameController.text.isNotEmpty
                    ? _nameController.text
                    : 'Your Name',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              if (_titleController.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _titleController.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_emailController.text.isNotEmpty)
                Text(
                  _emailController.text,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              if (_phoneController.text.isNotEmpty)
                Text(
                  _phoneController.text,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ),
        if (_includeQrCode) ...[
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.qr_code, size: 60),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBoldLayout() {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _companyController.text.isNotEmpty
                    ? _companyController.text
                    : 'Company',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text
                  : 'Your Name',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            if (_titleController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _titleController.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
            const Spacer(),
            if (_phoneController.text.isNotEmpty ||
                _emailController.text.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_phoneController.text.isNotEmpty)
                    Text(
                      _phoneController.text,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  if (_emailController.text.isNotEmpty)
                    Text(
                      _emailController.text,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.8)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text.length > 15 ? '${text.substring(0, 15)}...' : text,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Template',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedTemplate == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTemplate = index;
                  });
                  HapticService().lightImpact();
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: _templates[index].gradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          _templates[index].name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesignOptions() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Design Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _includeQrCode,
              onChanged: (value) {
                setState(() {
                  _includeQrCode = value;
                });
                HapticService().lightImpact();
              },
              title: const Text(
                'Include QR Code',
                style: TextStyle(color: Colors.white),
              ),
              activeColor: QuantumTheme.primaryBlue,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _includePhoto,
              onChanged: (value) {
                setState(() {
                  _includePhoto = value;
                });
                HapticService().lightImpact();
              },
              title: const Text(
                'Include Photo',
                style: TextStyle(color: Colors.white),
              ),
              activeColor: QuantumTheme.primaryBlue,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationFields() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('Name *', _nameController, Icons.person),
            const SizedBox(height: 12),
            _buildTextField('Title', _titleController, Icons.work),
            const SizedBox(height: 12),
            _buildTextField('Company', _companyController, Icons.business),
            const SizedBox(height: 12),
            _buildTextField('Email', _emailController, Icons.email),
            const SizedBox(height: 12),
            _buildTextField('Phone', _phoneController, Icons.phone),
            const SizedBox(height: 12),
            _buildTextField('Website', _websiteController, Icons.language),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: QuantumTheme.primaryBlue),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumTheme.deepSpace.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _saveCard,
              icon: const Icon(Icons.save),
              label: const Text('Save Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: QuantumTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card template model
class CardTemplate {
  final String name;
  final CardLayout layout;
  final Gradient gradient;

  CardTemplate({
    required this.name,
    required this.layout,
    required this.gradient,
  });
}

enum CardLayout {
  modern,
  classic,
  elegant,
  bold,
}

// Custom painter for card background pattern
class CardPatternPainter extends CustomPainter {
  final Color color;

  CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw diagonal lines pattern
    for (var i = 0; i < size.width + size.height; i += 30) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(0, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Provider for contact repository
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  throw UnimplementedError('ContactRepository provider not initialized');
});
