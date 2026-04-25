import 'package:flutter/material.dart';
import '../../../models/child_profile.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          backgroundImage: child.photoUrl.isNotEmpty ? NetworkImage(child.photoUrl) : null,
          child: child.photoUrl.isEmpty
              ? Icon(Icons.person, color: Colors.blue[800])
              : null,
        ),
        title: Text(
          child.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${child.age} anos • ${child.diagnosis.isNotEmpty ? child.diagnosis : "Sem diagnóstico"}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
