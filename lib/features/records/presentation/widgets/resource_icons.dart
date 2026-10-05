import 'package:flutter/material.dart';

/// Icon names usable in the module registry.
IconData resourceIcon(String name) => switch (name) {
      'cart' || 'orders' => Icons.shopping_bag_rounded,
      'calendar' || 'bookings' => Icons.event_available_rounded,
      'people' || 'customers' => Icons.people_alt_rounded,
      'menu' || 'food' => Icons.restaurant_menu_rounded,
      'product' || 'inventory' => Icons.inventory_2_rounded,
      'money' || 'invoice' => Icons.receipt_long_rounded,
      'task' || 'tasks' => Icons.task_alt_rounded,
      'chat' || 'messages' => Icons.forum_rounded,
      'car' => Icons.directions_car_rounded,
      'health' || 'medical' => Icons.medical_services_rounded,
      'school' || 'courses' => Icons.school_rounded,
      'home' || 'property' => Icons.home_work_rounded,
      'star' || 'reviews' => Icons.star_rounded,
      'location' => Icons.place_rounded,
      'chart' || 'reports' => Icons.insights_rounded,
      _ => Icons.grid_view_rounded,
    };
