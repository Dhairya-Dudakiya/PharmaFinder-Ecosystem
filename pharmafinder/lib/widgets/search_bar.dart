import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search medicines, pharmacies...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Color(0xFF0A7B79)),
              onPressed: () {},
            ),
          ),
          filled: true,
          fillColor: const Color(0xFF0A7B79).withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
        ),
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        onTap: () {
          // Navigate to search screen
        },
      ),
    );
  }
}
