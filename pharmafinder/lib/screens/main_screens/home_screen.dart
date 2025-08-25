import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pharmafinder/models/medicine_model.dart';
import 'package:pharmafinder/screens/auth_screens/login_screen.dart';
import 'package:pharmafinder/screens/main_screens/medicine_detail_screen.dart';
import 'package:pharmafinder/screens/main_screens/profile_screen.dart';
import 'package:pharmafinder/screens/main_screens/settings_screen.dart';
import 'package:pharmafinder/screens/main_screens/cart_screen.dart';
import 'package:pharmafinder/screens/main_screens/my_inquiries_screen.dart';
import 'package:pharmafinder/screens/main_screens/my_orders_screen.dart';
import 'package:pharmafinder/screens/main_screens/search_screen.dart';
import 'package:pharmafinder/screens/main_screens/symptom_inquiry_screen.dart';
import 'package:pharmafinder/services/medicine_service.dart';
import 'package:pharmafinder/services/auth_service.dart';
import 'package:pharmafinder/widgets/MedicineCard.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

// ViewModel remains the same as it's already well-structured.
class HomeScreenViewModel extends ChangeNotifier {
  final MedicineService _medicineService = MedicineService();

  List<Medicine> _allMedicines = [];
  List<Medicine> get allMedicines => _allMedicines;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _selectedLocation = "Fetching location...";
  String get selectedLocation => _selectedLocation;

  HomeScreenViewModel() {
    _initialize();
  }

  void _initialize() {
    _fetchAllMedicinesOnce();
    _getCurrentLocation();
  }

  Future<void> _fetchAllMedicinesOnce() async {
    try {
      _allMedicines = await _medicineService.fetchAllMedicines();
    } catch (e) {
      _errorMessage = "Failed to load medicines: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _selectedLocation = 'Location services are disabled.';
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _selectedLocation = 'Location permissions are denied.';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _selectedLocation = 'Location permissions are permanently denied.';
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final addressParts = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
        ].where((part) => part != null && part.isNotEmpty).toList();
        _selectedLocation = addressParts.join(', ');
      } else {
        _selectedLocation = "Could not determine address.";
      }
    } catch (e) {
      _selectedLocation = "Could not get location.";
    }
    notifyListeners();
  }

  List<Medicine> getMedicinesForCategory(String category) {
    if (category == 'All') {
      return _allMedicines;
    }
    return _allMedicines
        .where((m) => m.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeScreenViewModel(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  final List<String> _categories = [
    'All',
    'Pain Relief',
    'Cold & Flu',
    'Allergy',
    'Digestive',
    'Antibiotic',
    'Skin Care',
    'Vitamins',
    'Diabetes',
    'Blood Pressure',
    'Mental Health',
    'First Aid',
    'Eye Care',
    'Heart Health',
    'Women\'s Health',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _startBannerAutoScroll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        int nextPage = _bannerController.page!.toInt() + 1;
        if (nextPage >= 3) {
          nextPage = 0;
        }
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeScreenViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: _buildLocationBar(viewModel.selectedLocation),
                ),
                SliverToBoxAdapter(child: _buildPromoBanner()),
                SliverToBoxAdapter(child: _buildAskPharmacistCard()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.teal,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.teal,
                      tabs: _categories.map((cat) => Tab(text: cat)).toList(),
                    ),
                  ),
                ),
              ],
              body: viewModel.isLoading
                  ? const _MedicineGridShimmer()
                  : viewModel.errorMessage != null
                  ? Center(child: Text(viewModel.errorMessage!))
                  : TabBarView(
                      controller: _tabController,
                      children: _categories.map((category) {
                        final filteredList = viewModel.getMedicinesForCategory(
                          category,
                        );
                        return _buildMedicineGrid(filteredList);
                      }).toList(),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 2,
      backgroundColor: Colors.teal,
      title: const Text(
        'PharmaFinder',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                break;
              // ✅ NEW: Case for navigating to My Orders
              case 'orders':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                );
                break;
              case 'inquiries':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyInquiriesScreen()),
                );
                break;
              case 'settings':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                break;
              case 'logout':
                _confirmLogout();
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('My Profile'),
              ),
            ),
            // ✅ NEW: Added "My Orders" to the menu
            const PopupMenuItem<String>(
              value: 'orders',
              child: ListTile(
                leading: Icon(Icons.receipt_long_outlined),
                title: Text('My Orders'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'inquiries',
              child: ListTile(
                leading: Icon(Icons.question_answer_outlined),
                title: Text('My Inquiries'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationBar(String location) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              location,
              style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    final List<Widget> banners = [
      _buildBannerItem(
        'assets/images/banner1.png',
        'Flat 25% Off\non all vitamins',
      ),
      _buildBannerItem(
        'assets/images/banner2.png',
        'Fast Delivery\nGet medicines in 30 mins',
      ),
      _buildBannerItem(
        'assets/images/banner3.png',
        'Free Health Checkup\nwith orders above ₹500',
      ),
    ];

    return Container(
      height: 150,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: PageView(controller: _bannerController, children: banners),
    );
  }

  Widget _buildAskPharmacistCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SymptomInquiryScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.green.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: Colors.teal,
                  size: 40,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Not Sure What to Get?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Describe your symptoms and get a recommendation from a pharmacist.",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerItem(String imagePath, String text) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineGrid(List<Medicine> medicines) {
    if (medicines.isEmpty) {
      return const Center(child: Text('No medicines found in this category.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicines.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final medicine = medicines[index];
        return MedicineCard(
          medicine: medicine,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicineDetailScreen(medicine: medicine),
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MedicineGridShimmer extends StatelessWidget {
  const _MedicineGridShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 40, height: 40, color: Colors.white),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 12, color: Colors.white),
                  const Spacer(),
                  Container(width: 60, height: 20, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  const _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
