// lib/pages/profile/change_password_dialog.dart
// ✅ COMPLETAMENTE CORREGIDO - Uso de métodos estáticos

import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class ChangePasswordDialog extends StatefulWidget {
  final int userId;

  const ChangePasswordDialog({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ CORRECCIÓN: Usar AdminService.changePassword() estático
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // ✅ CORRECCIÓN: AdminService.changePassword() es ESTÁTICO
      final result = await AdminService.changePassword(
        userId: widget.userId,
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        // ✅ Verificar resultado
        if (result['success'] == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Contraseña actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Error al cambiar contraseña'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock, color: Colors.teal, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cambiar Contraseña',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: 'Mínimo 6 caracteres',
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requerido';
                  if (v!.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requerido';
                  if (v != _newPasswordController.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _loading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Cambiar Contraseña'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}