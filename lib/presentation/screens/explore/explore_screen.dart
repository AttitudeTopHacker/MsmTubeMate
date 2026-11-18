import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/app_constants.dart';
import '../../../config/theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/url_utils.dart';
import '../../widgets/format_bottom_sheet.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';

class ExploreScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const ExploreScreen({super.key, this.onNavigateTab});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();

  String _detectedClipboardUrl = '';
  String _selectedSubNav = 'Discover';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  final List<String> _subNavigationChips = [
    'Discover',
    'Trending Videos',
    'Music Mixes',
    'Sites',
  ];

  @override
  void initState() {
    super.initState();
    _checkClipboardForUrl();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _checkClipboardForUrl() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        final extracted = UrlUtils.extractUrl(data.text!);
        if (extracted != null && extracted.isNotEmpty) {
          setState(() {
            _detectedClipboardUrl = extracted;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleSearchOrExtract(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    final extractedUrl = UrlUtils.extractUrl(query);
    if (extractedUrl != null) {
      // It's a direct URL -> open format selection bottom sheet
      FormatBottomSheet.show(context, extractedUrl);
      return;
    }

    // It's a search keyword -> perform search via backend / Dart
    setState(() => _isSearching = true);
    final results = await _api.search(query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header with Mandatory Subtitle 'ORG: msm.movin 2022'
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentCyan.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF090D16),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                          // MANDATORY PRD Subtitle
                          Text(
                            AppConstants.organization,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GlassContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          user != null
                              ? Icons.check_circle_rounded
                              : Icons.person_outline_rounded,
                          color: user != null ? AppTheme.accentCyan : Colors.white60,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user != null ? 'Synced' : 'Guest',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Clipboard Auto-Detect Floating Glass Banner
              if (_detectedClipboardUrl.isNotEmpty) ...[
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  opacity: 0.14,
                  customBorder: Border.all(
                    color: AppTheme.accentCyan.withValues(alpha: 0.45),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded,
                          color: AppTheme.accentCyan, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Link detected from clipboard!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _detectedClipboardUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final url = _detectedClipboardUrl;
                          setState(() => _detectedClipboardUrl = '');
                          FormatBottomSheet.show(context, url);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accentCyan,
                        ),
                        child: const Text('Download'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: Colors.white54),
                        onPressed: () =>
                            setState(() => _detectedClipboardUrl = ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Top Glass Search Bar
              GlassContainer(
                borderRadius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: AppTheme.accentCyan, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search or paste YouTube, Insta, X link...',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        onSubmitted: _handleSearchOrExtract,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_paste_rounded,
                          color: AppTheme.accentCyan, size: 20),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          _searchController.text = data!.text!;
                          _handleSearchOrExtract(data.text!);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Sub-Navigation Glass Chips (Discover | Trending | Music | Sites)
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _subNavigationChips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final chip = _subNavigationChips[index];
                    final isSelected = _selectedSubNav == chip;

                    return GlassContainer(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      opacity: isSelected ? 0.24 : 0.08,
                      customBorder: Border.all(
                        color: isSelected
                            ? AppTheme.accentCyan
                            : Colors.white.withValues(alpha: 0.12),
                        width: isSelected ? 1.4 : 1.0,
                      ),
                      onTap: () {
                        setState(() => _selectedSubNav = chip);
                        if (chip == 'Trending Videos') {
                          _handleSearchOrExtract('Trending');
                        } else if (chip == 'Music Mixes') {
                          _handleSearchOrExtract('Music Mix');
                        }
                      },
                      child: Center(
                        child: Text(
                          chip,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Search Results (if available)
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
                    ),
                  ),
                )
              else if (_searchResults.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search Results (${_searchResults.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _searchResults.clear()),
                      child: const Text('Clear', style: TextStyle(color: AppTheme.accentCyan)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      borderRadius: 14,
                      onTap: () {
                        FormatBottomSheet.show(context, item['webpage_url']);
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.play_circle_outline_rounded,
                              color: AppTheme.accentCyan, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? 'Media',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  item['channel'] ?? '',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.download_rounded,
                              color: AppTheme.accentCyan, size: 20),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
              ],

              // Quick Sites Grid (Glass Cards)
              const Text(
                'Quick Sites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSiteCard(
                    title: 'YouTube',
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFFFF0000),
                    onTap: () => _searchController.text = 'https://www.youtube.com/watch?v=',
                  ),
                  _buildSiteCard(
                    title: 'Instagram',
                    icon: Icons.camera_alt_outlined,
                    color: const Color(0xFFE1306C),
                    onTap: () => _searchController.text = 'https://www.instagram.com/reel/',
                  ),
                  _buildSiteCard(
                    title: 'Status Saver',
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF25D366),
                    onTap: () => widget.onNavigateTab?.call(2), // Tools tab
                  ),
                  _buildSiteCard(
                    title: 'Twitter / X',
                    icon: Icons.tag_rounded,
                    color: const Color(0xFF1DA1F2),
                    onTap: () => _searchController.text = 'https://x.com/',
                  ),
                  _buildSiteCard(
                    title: 'Facebook',
                    icon: Icons.facebook_rounded,
                    color: const Color(0xFF1877F2),
                    onTap: () => _searchController.text = 'https://www.facebook.com/watch/',
                  ),
                  _buildSiteCard(
                    title: '+ Add Site',
                    icon: Icons.add_rounded,
                    color: AppTheme.accentCyan,
                    onTap: _showAddBookmarkDialog,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Interactive "How to Download" Guide
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentCyan.withValues(alpha: 0.16),
                          ),
                          child: const Icon(Icons.share_rounded,
                              color: AppTheme.accentCyan, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'How to Download Instantly',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Open YouTube, Instagram or X and tap "Share".\n'
                      '2. Select "Msm TubeMate" from your phone\'s share list.\n'
                      '3. A frosted glass dialog pops up from the bottom with 4K, 1080p, and MP3 options.\n'
                      '4. Tap Download and continue using your favorite apps uninterrupted!',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSiteCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(
                color: color.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBookmarkDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: const Text('Add Custom Site', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Site Name (e.g. Soundcloud)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'URL (https://...)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          GlassButton(
            isPrimary: true,
            height: 38,
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom site saved to your bookmarks')),
              );
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF090D16), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
