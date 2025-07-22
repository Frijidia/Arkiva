import 'package:flutter/material.dart';
import 'package:arkiva/models/document.dart';
import 'package:arkiva/services/favoris_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';

class FavoriButton extends StatefulWidget {
  final Document document;
  final VoidCallback? onToggle;
  final double size;
  final Color? color;

  const FavoriButton({
    super.key,
    required this.document,
    this.onToggle,
    this.size = 24.0,
    this.color,
  });

  @override
  State<FavoriButton> createState() => _FavoriButtonState();
}

class _FavoriButtonState extends State<FavoriButton> {
  final FavorisService _favorisService = FavorisService();
  bool _isFavori = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriStatus();
  }

  Future<void> _checkFavoriStatus() async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final userId = authState.userId;

      if (token != null && userId != null) {
        final isFavori = await _favorisService.isFavori(token, int.parse(userId), int.parse(widget.document.id));
        if (mounted) {
      setState(() {
        _isFavori = isFavori;
        _isLoading = false;
      });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavori() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final userId = authState.userId;
      final entrepriseId = authState.entrepriseId;

      if (token == null || userId == null || entrepriseId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Informations d\'authentification manquantes')),
        );
        return;
      }

      if (_isFavori) {
        await _favorisService.removeFavori(token, int.parse(userId), int.parse(widget.document.id));
        setState(() => _isFavori = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document retiré des favoris')),
        );
      } else {
        await _favorisService.addFavori(token, int.parse(userId), int.parse(widget.document.id), entrepriseId!);
        setState(() => _isFavori = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document ajouté aux favoris')),
        );
      }

      // Appeler le callback si fourni
      widget.onToggle?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la gestion des favoris: $e')),
      );
    } finally {
      if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      onPressed: _toggleFavori,
      icon: Icon(
        _isFavori ? Icons.favorite : Icons.favorite_border,
              size: widget.size,
        color: _isFavori ? (widget.color ?? Colors.red) : widget.color,
            ),
      tooltip: _isFavori ? 'Retirer des favoris' : 'Ajouter aux favoris',
    );
  }
} 