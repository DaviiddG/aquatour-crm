import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;

  const CustomButton({super.key, required this.text, required this.onPressed, this.color});

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: widget.color,
            gradient: widget.color == null
                ? const LinearGradient(
                    colors: [Color(0xFFfdb913), Color(0xFFf7941e)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _isHovering
                    ? (widget.color ?? const Color(0xFFf7941e)).withOpacity(0.6)
                    : Colors.black.withOpacity(0.2),
                blurRadius: _isHovering ? 12.0 : 5.0,
                spreadRadius: 1.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
