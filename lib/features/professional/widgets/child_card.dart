import 'package:flutter/material.dart';
import '../../../models/child_profile.dart';
import '../../../models/user_progress_model.dart';

class ChildCard extends StatelessWidget {
  final ChildProfile child;
  final VoidCallback onTap;

  const ChildCard({
    Key? key,
    required this.child,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final daysInactive = DateTime.now().difference(child.lastActive).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(daysInactive),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.calendar_today,
                        child.age != null ? '${child.age} anos' : 'Idade não informada'),
                    const SizedBox(height: 2),
                    _buildInfoRow(Icons.access_time,
                        _formatLastAccess(child.lastActive)),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildStatusBadge(daysInactive),
                  const SizedBox(height: 8),
                  Text(
                    '${child.totalPhrases}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'frases',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(int daysInactive) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _getStatusColor(daysInactive),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: _getStatusColor(daysInactive).withOpacity(0.1),
        child: Text(
          child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(daysInactive),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int daysInactive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(daysInactive).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(daysInactive),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(daysInactive),
            style: TextStyle(
              fontSize: 10,
              color: _getStatusColor(daysInactive),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int daysInactive) {
    if (daysInactive == 0) return Colors.green;
    if (daysInactive <= 3) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(int daysInactive) {
    if (daysInactive == 0) return 'Hoje';
    if (daysInactive == 1) return 'Ontem';
    if (daysInactive <= 3) return '$daysInactive dias';
    return 'Inativo';
  }

  String _formatLastAccess(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      return 'Ontem';
    } else if (difference <= 7) {
      return 'Há $difference dias';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}