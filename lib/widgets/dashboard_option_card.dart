import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardOptionCard extends StatefulWidget {
  const DashboardOptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
    this.badge,
  });

  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;
  final String? badge;

  @override
  State<DashboardOptionCard> createState() => _DashboardOptionCardState();
}

class _DashboardOptionCardState extends State<DashboardOptionCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: _isHovering ? 1.02 : 1,
        duration: const Duration(milliseconds: 180),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: _isHovering
                  ? [
                      const Color(0xFF3D1F6E).withOpacity(0.12),
                      const Color(0xFF4C39A6).withOpacity(0.08),
                    ]
                  : [
                      Colors.white,
                      Colors.white,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovering ? 0.12 : 0.06),
                blurRadius: _isHovering ? 18 : 12,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: _isHovering
                  ? const Color(0xFFfdb913).withOpacity(0.6)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D1F6E).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 28,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1F1F1F),
                                      ),
                                    ),
                                  ),
                                  if (widget.badge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFfdb913).withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        widget.badge!,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFf7941e),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.description,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF5C5C5C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton.icon(
                        onPressed: widget.onTap,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                          textStyle: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Ir al módulo'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
