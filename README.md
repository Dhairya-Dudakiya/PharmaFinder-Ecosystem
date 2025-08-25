PharmaFinder: A Complete Pharmacy Delivery Ecosystem
This repository contains the source code for PharmaFinder, a comprehensive, real-time pharmacy delivery ecosystem built with Flutter and Firebase. The project consists of three distinct yet interconnected applications designed to create a seamless and efficient experience for customers, pharmacy admins, and delivery riders.

The primary goal of this project was to solve the common challenges in local medicine delivery by building a robust, scalable, and real-time platform that handles everything from inventory management to final-mile delivery tracking.

🎥 Project Demo
[https://www.linkedin.com/posts/dhairya-dudakiya_flutter-firebase-mobileappdevelopment-activity-7365473961968656386-C1Vp?utm_source=share&utm_medium=member_desktop&rcm=ACoAAD8KVBQBVHLBRA0c1ngOOriR6QArTcKMxCM]

🏛️ System Architecture
The ecosystem is built on a centralized Firebase backend, with each Flutter application serving a specific user role. Data flows in real-time between the apps to ensure all parties have the most up-to-date information.

Firebase Authentication provides a unified login system for all three apps.

Cloud Firestore is used for structured data that requires complex querying, such as user profiles, orders, and symptom inquiries.

Realtime Database is leveraged for data that needs low-latency synchronization, such as the core medicine inventory.

Cloud Functions are used for secure, server-side operations that cannot be trusted to the client, such as creating new rider accounts.

📱 The Three Applications
1. 🛍️ User App (pharmafinder)
The primary customer-facing application, designed for a smooth and intuitive user experience.

Features:

Real-Time Inventory: Browse medicines by category across multiple local pharmacies with live data synced from the Realtime Database.

Global Search: A powerful search screen to find specific medicines or stores.

Symptom Inquiry: A unique feature allowing users to describe their symptoms in a form. The inquiry is saved to Firestore, allowing a pharmacist from the admin app to review and respond with medicine suggestions.

Precise Location Selection: Integrated Google Maps for users to drop a pin for their exact delivery location, saving the precise coordinates to the order to ensure delivery accuracy.

Live Order Tracking: A "My Orders" screen that listens to real-time Firestore updates, allowing users to track their order status from "Pending" to "Delivered".

State Management: Built using the provider package for efficient and scalable state management.

2. ⚙️ Admin Panel (pharmafinderadmin)
The command center for pharmacy owners to manage their entire operation.

Features:

Full Inventory Control: Complete CRUD (Create, Read, Update, Delete) functionality for the medicine inventory stored in the Realtime Database.

Bulk Inventory Upload: An efficient tool for admins to upload their entire inventory at once using a pre-formatted CSV file.

Live Order Dashboard: A real-time stream of incoming orders from Firestore, specific to the admin's store.

Secure Rider Creation: A dedicated screen for admins to create new accounts for their delivery personnel. This is handled securely by a Firebase Cloud Function, which is the only part of the system with the authority to create new users.

Pharmacist Consultation Hub: A dedicated interface to view and respond to user symptom inquiries, strengthening the pharmacy-customer relationship.

3. 🛵 Delivery App (pharmafinderrider)
A focused and efficient tool designed to streamline the delivery process for personnel.

Features:

Role-Based Access Control: A secure login system that checks Firestore to ensure that only users with a "rider" role can access the application.

Tabbed Order Queue: A clean, tabbed dashboard showing new, in-progress, and completed orders, allowing riders to easily manage their workflow.

Live Map Navigation: Upon accepting an order, the rider sees an integrated Google Map with markers for their current location, the pharmacy pickup point, and the customer's precise drop-off coordinates.

Real-Time Status Updates: Riders can update the order status with the tap of a button, which instantly updates the order document in Firestore and notifies the customer in their app.

🛠️ Tech Stack
Frontend: Flutter

Backend & Database: Firebase (Authentication, Firestore, Realtime Database, Cloud Functions)

APIs & Services: Google Maps SDK, Geocoding API

State Management (User App): Provider
