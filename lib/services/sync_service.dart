import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_progress_model.dart';
import '../models/child_profile.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 CORAÇÃO DA SINCRONIZAÇÃO - Salva na coleção 'children'
  Future<void> syncProgress(String childId, UserProgress progress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Nenhum usuário logado, não é possível sincronizar');
        return;
      }

      // Busca o documento da criança primeiro para manter os dados existentes
      final childDoc = await _firestore.collection('children').doc(childId).get();

      Map<String, dynamic> updateData = {
        'totalStars': progress.totalStars,
        'totalPhrasesBuilt': progress.totalPhrasesBuilt,
        'totalSessions': progress.totalSessions,
        'categoryUsage': progress.categoryUsage,
        'pictogramUsage': progress.pictogramUsage,
        'lastActive': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Se o documento não existe, cria com informações básicas
      if (!childDoc.exists) {
        updateData['id'] = childId;
        updateData['createdAt'] = FieldValue.serverTimestamp();
        updateData['professionalIds'] = [user.uid, user.email ?? ''];
        updateData['name'] = 'Criança $childId'; // Nome temporário
      }

      // Salva no Firestore
      await _firestore.collection('children').doc(childId).set(
        updateData,
        SetOptions(merge: true),
      );

      debugPrint('✅ Progresso sincronizado para criança $childId: ${progress.totalStars} estrelas, ${progress.totalPhrasesBuilt} frases');
      debugPrint('   Categorias usadas: ${progress.categoryUsage}');

    } catch (e) {
      debugPrint('❌ Erro na sincronização do progresso: $e');
    }
  }

  // Salvar perfil completo da criança
  Future<void> syncChildProfile(ChildProfile child) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('children').doc(child.id).set({
        'id': child.id,
        'name': child.name,
        'age': child.age,
        'diagnosis': child.diagnosis,
        'professionalIds': child.professionalIds,
        'settings': {
          'voiceRate': child.settings.voiceRate,
          'voicePitch': child.settings.voicePitch,
          'highContrast': child.settings.highContrast,
          'selectedVoice': child.settings.selectedVoice,
        },
        'progress': {
          'totalStars': child.progress.totalStars,
          'totalPhrasesBuilt': child.progress.totalPhrasesBuilt,
          'totalSessions': child.progress.totalSessions,
          'categoryUsage': child.progress.categoryUsage,
          'pictogramUsage': child.progress.pictogramUsage,
        },
        'createdAt': child.createdAt,
        'lastActive': child.lastActive,
      }, SetOptions(merge: true));

      debugPrint('✅ Perfil da criança ${child.name} sincronizado');
    } catch (e) {
      debugPrint('❌ Erro ao sincronizar perfil: $e');
    }
  }

  // Buscar dados do progresso (para recuperação)
  Future<UserProgress?> fetchProgress(String childId) async {
    try {
      final doc = await _firestore.collection('children').doc(childId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return UserProgress(
        userId: childId,
        totalStars: data['totalStars'] ?? 0,
        totalPhrasesBuilt: data['totalPhrasesBuilt'] ?? 0,
        totalSessions: data['totalSessions'] ?? 0,
        categoryUsage: Map<String, int>.from(data['categoryUsage'] ?? {}),
        pictogramUsage: Map<String, int>.from(data['pictogramUsage'] ?? {}),
      );
    } catch (e) {
      debugPrint('❌ Erro ao buscar progresso: $e');
      return null;
    }
  }

  // Verificar se a criança está vinculada ao profissional atual
  Future<bool> isLinkedToProfessional(String childId) async {
    try {
      final doc = await _firestore.collection('children').doc(childId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> profIds = data['professionalIds'] ?? [];
      final user = _auth.currentUser;

      return profIds.contains(user?.uid) || profIds.contains(user?.email);
    } catch (e) {
      debugPrint('❌ Erro ao verificar vínculo: $e');
      return false;
    }
  }
}