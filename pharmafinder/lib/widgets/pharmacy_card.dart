import 'package:flutter/material.dart';
import 'package:pharmafinder/models/pharmacy_model.dart';

class PharmacyCard extends StatelessWidget {
  final Pharmacy pharmacy;

  const PharmacyCard({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to pharmacy detail
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pharmacy Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: pharmacy.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(pharmacy.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: pharmacy.imageUrl == null
                        ? const LinearGradient(
                            colors: [Color(0xFF0A7B79), Color(0xFF39B9B7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: pharmacy.imageUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.local_pharmacy,
                            size: 36,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Pharmacy Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pharmacy.address,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: pharmacy.isOpen
                                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                                  : const Color(0xFFF44336).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pharmacy.isOpen ? 'OPEN NOW' : 'CLOSED',
                              style: TextStyle(
                                color: pharmacy.isOpen
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFF44336),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A7B79).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${pharmacy.distance} km',
                              style: const TextStyle(
                                color: Color(0xFF0A7B79),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            pharmacy.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            ' (${pharmacy.reviewCount})',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          Text(
                            '${pharmacy.deliveryTime} min',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
