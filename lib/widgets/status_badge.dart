import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';

class StatusBadge extends StatelessWidget {
   final ReportStatus status;

   const StatusBadge({Key? key, required this.status}) : super(key: key);

   @override
   Widget build(BuildContext context) {
     Color baseColor;
     String text;

     switch (status) {
       case ReportStatus.submitted:
         baseColor = AppTheme.statusMedium; // Orange/Amber
         text = 'Diajukan';
         break;
       case ReportStatus.processed:
         baseColor = const Color(0xFF005BC1); // Processed Blue
         text = 'Diproses';
         break;
       case ReportStatus.resolved:
         baseColor = AppTheme.statusLow; // Selesai Green
         text = 'Selesai';
         break;
     }

     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
       decoration: BoxDecoration(
         color: baseColor.withOpacity(0.15),
         borderRadius: BorderRadius.circular(100),
       ),
       child: Text(
         text,
         style: Theme.of(context).textTheme.labelSmall?.copyWith(
               color: baseColor,
               fontWeight: FontWeight.bold,
               fontSize: 10,
             ),
       ),
     );
   }
}

class PriorityBadge extends StatelessWidget {
   final ReportPriority priority;

   const PriorityBadge({Key? key, required this.priority}) : super(key: key);

   @override
   Widget build(BuildContext context) {
     Color baseColor;
     Color bgContainerColor;
     String text;

     switch (priority) {
       case ReportPriority.high:
         baseColor = AppTheme.statusHigh;
         bgContainerColor = AppTheme.statusHighContainer;
         text = 'Tinggi';
         break;
       case ReportPriority.medium:
         baseColor = AppTheme.statusMedium;
         bgContainerColor = AppTheme.statusMedium.withOpacity(0.15);
         text = 'Sedang';
         break;
       case ReportPriority.low:
         baseColor = AppTheme.statusLow;
         bgContainerColor = AppTheme.statusLow.withOpacity(0.15);
         text = 'Rendah';
         break;
     }

     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
       decoration: BoxDecoration(
         color: bgContainerColor,
         borderRadius: BorderRadius.circular(6),
       ),
       child: Text(
         text.toUpperCase(),
         style: Theme.of(context).textTheme.labelSmall?.copyWith(
               color: baseColor,
               fontWeight: FontWeight.bold,
               fontSize: 9,
               letterSpacing: 0.5,
             ),
       ),
     );
   }
}
