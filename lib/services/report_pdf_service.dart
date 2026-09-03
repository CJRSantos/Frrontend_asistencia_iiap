import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';

class ReportPdfService {
  static Future<void> exportMonthlyReport({
    required UserModel user,
    required List<AttendanceModel> historyList,
    required String monthName,
    required int year,
  }) async {
    final doc = pw.Document();

    // Calcular estadísticas del mes
    final totalMarks = historyList.length;
    final checkIns = historyList.where((h) => h.type == 'CHECK_IN').length;
    final checkOuts = historyList.where((h) => h.type == 'CHECK_OUT').length;
    final onTimeMarks = historyList.where((h) => h.status == 'ON_TIME').length;
    final lateMarks = historyList.where((h) => h.status == 'LATE').length;
    final earlyDepartures = historyList.where((h) => h.status == 'EARLY_DEPARTURE').length;

    // Colores institucionales
    const primaryGreen = PdfColor.fromInt(0xFF2D5E2A);
    const lightGreen = PdfColor.fromInt(0xFFE8F5E9);
    
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildUserInfoCard(user, monthName, year, primaryGreen, lightGreen),
          pw.SizedBox(height: 16),
          _buildKpiSummary(totalMarks, checkIns, checkOuts, onTimeMarks, lateMarks, earlyDepartures),
          pw.SizedBox(height: 20),
          pw.Text(
            'DETALLE CRONOLÓGICO DE MARCACIONES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildAttendanceTable(historyList),
          pw.SizedBox(height: 30),
          _buildSignatures(),
        ],
      ),
    );

    // Abrir pantalla nativa de impresión / compartir / guardar PDF
    await Printing.layoutPdf(
      name: 'Reporte_Asistencia_IIAP_${user.fullName.replaceAll(' ', '_')}_$monthName-$year.pdf',
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF2D5E2A), width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INSTITUTO DE INVESTIGACIONES DE LA AMAZONÍA PERUANA',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF2D5E2A)),
              ),
              pw.Text(
                'SISTEMA INTEGRAL DE CONTROL DE ASISTENCIA BIOMÉTRICO (IIAP)',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF2D5E2A),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'REPORTE OFICIAL',
              style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildUserInfoCard(UserModel user, String month, int year, PdfColor primary, PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: accent,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: primary, width: 0.8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('COLABORADOR:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Text(user.fullName.toUpperCase(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('CARGO / FUNCIÓN: ${user.position ?? "Investigador / Personal Institucional"}', style: const pw.TextStyle(fontSize: 8.5)),
              pw.Text('ÁREA / PROYECTO: ${user.department ?? "Sede Central Iquitos"}', style: const pw.TextStyle(fontSize: 8.5)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('PERIODO:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Text('$month $year'.toUpperCase(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primary)),
              pw.SizedBox(height: 4),
              pw.Text('DOCUMENTO: ${user.documentNumber ?? "Registrado"}', style: const pw.TextStyle(fontSize: 8.5)),
              pw.Text('FECHA EMISIÓN: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildKpiSummary(int total, int ins, int outs, int onTime, int late, int early) {
    return pw.Row(
      children: [
        _buildKpiBox('Total Marcas', total.toString(), PdfColors.blueGrey800),
        pw.SizedBox(width: 8),
        _buildKpiBox('Ingresos', ins.toString(), const PdfColor.fromInt(0xFF2D5E2A)),
        pw.SizedBox(width: 8),
        _buildKpiBox('Salidas', outs.toString(), const PdfColor.fromInt(0xFF1E3A8A)),
        pw.SizedBox(width: 8),
        _buildKpiBox('Puntuales', onTime.toString(), const PdfColor.fromInt(0xFF16A34A)),
        pw.SizedBox(width: 8),
        _buildKpiBox('Tardanzas', late.toString(), const PdfColor.fromInt(0xFFDC2626)),
      ],
    );
  }

  static pw.Widget _buildKpiBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 2),
            pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildAttendanceTable(List<AttendanceModel> list) {
    if (list.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        alignment: pw.Alignment.center,
        child: pw.Text('No se encontraron registros de marcación en el periodo.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      );
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2D5E2A)),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      cellAlignment: pw.Alignment.centerLeft,
      headers: ['N°', 'Fecha', 'Hora', 'Tipo', 'Estado', 'Ubicación / Observaciones'],
      data: List.generate(list.length, (index) {
        final item = list[index];
        final dt = DateTime.tryParse(item.timestamp);
        final dateStr = dt != null ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}' : '-';
        final timeStr = dt != null ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}' : '-';
        final typeStr = item.type == 'CHECK_IN' ? 'Ingreso' : 'Salida';
        final statusStr = item.status == 'ON_TIME' ? 'Puntual' : (item.status == 'LATE' ? 'Tardanza' : item.status);
        final obs = item.observations ?? 'Sede Central IIAP';

        return [
          (index + 1).toString(),
          dateStr,
          timeStr,
          typeStr,
          statusStr,
          obs,
        ];
      }),
    );
  }

  static pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        pw.Column(
          children: [
            pw.Container(width: 140, height: 1, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text('Firma del Colaborador', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        pw.Column(
          children: [
            pw.Container(width: 140, height: 1, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text('V°B° Recursos Humanos / IIAP', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('IIAP - Av. Abelardo Quiñones km 2.5, Iquitos, Perú', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
          pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}
