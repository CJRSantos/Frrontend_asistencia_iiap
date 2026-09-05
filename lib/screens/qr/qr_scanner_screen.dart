import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../widgets/app_button.dart';

enum ScanTarget {
  attendance,
  supervisorPromotion,
}

class QrScannerScreen extends StatefulWidget {
  final ScanTarget target;

  const QrScannerScreen({
    super.key,
    this.target = ScanTarget.attendance,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;
  bool _torchEnabled = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(String rawCode) async {
    if (_isProcessing) return;
    final cleanCode = rawCode.trim();
    if (cleanCode.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      if (widget.target == ScanTarget.attendance) {
        final result = await AttendanceService.scanAttendanceQr(qrCode: cleanCode);
        if (!mounted) return;

        await _showSuccessDialog(
          title: '¡Asistencia Registrada!',
          message: result.message,
          detail: 'Marca: ${result.typeLabel ?? "REGISTRO"} • ${result.formattedTime ?? ""}',
          isShaVerified: true,
        );
      } else {
        final result = await AttendanceService.scanSupervisorQr(cleanCode);
        await AuthService.getProfile();
        if (!mounted) return;

        await _showSuccessDialog(
          title: '¡Ascenso a Supervisor!',
          message: result['message']?.toString() ?? 'Ahora eres Supervisor institucional.',
          detail: 'Tu perfil ha sido actualizado con los nuevos permisos.',
          isShaVerified: true,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      await _showErrorDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Error al procesar el código: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
    String? detail,
    bool isShaVerified = false,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 44),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            if (isShaVerified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                    SizedBox(width: 5),
                    Text(
                      'Código Criptográfico SHA-256 Verificado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (detail != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: AppButton(
              text: 'Aceptar',
              width: 140,
              height: 42,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String error) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFFEE2E2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
        ),
        title: const Text('No se pudo procesar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
        actions: [
          Center(
            child: AppButton(
              text: 'Reintentar',
              width: 130,
              height: 42,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }

  void _openManualInputDialog() {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            widget.target == ScanTarget.attendance
                ? 'Ingreso de Hash QR (SHA-256)'
                : 'Código de Designación',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pega el Hash SHA-256 emitido por el Administrador o Supervisor:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Pega el Hash SHA-256 aquí...',
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final code = textCtrl.text.trim();
                if (code.isNotEmpty) {
                  Navigator.of(ctx).pop();
                  _handleBarcodeDetected(code);
                }
              },
              child: const Text('Validar Marca'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAttendance = widget.target == ScanTarget.attendance;
    final title = isAttendance ? 'Escanear QR de Asistencia' : 'Escanear Ascenso a Supervisor';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchEnabled ? const Color(0xFFFBBF24) : Colors.white,
            ),
            tooltip: 'Linterna',
            onPressed: () {
              setState(() => _torchEnabled = !_torchEnabled);
              _scannerController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined),
            tooltip: 'Ingresar Hash Manual',
            onPressed: _openManualInputDialog,
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Vista de la cámara de escaneo
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _handleBarcodeDetected(rawValue);
                  break;
                }
              }
            },
          ),

          // Máscara y marco de encuadre visual del QR
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 260,
                    width: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Marco con esquinas redondeadas
          Container(
            height: 260,
            width: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF22C55E), width: 3),
            ),
          ),

          // Indicador de procesamiento
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Validando código SHA-256 en el servidor...',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Instrucciones al pie de pantalla
          Positioned(
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF4ADE80), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isAttendance
                        ? 'Enfoca el código QR SHA emitido por el supervisor'
                        : 'Enfoca el QR otorgado por el Administrador',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}