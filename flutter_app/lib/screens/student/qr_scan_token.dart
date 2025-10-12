import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api/qr_repository.dart';
import 'checkin_screen.dart';
class QrScanTokenPage extends StatefulWidget{ const QrScanTokenPage({super.key}); @override State<QrScanTokenPage> createState()=>_QrScanTokenPageState(); }
class _QrScanTokenPageState extends State<QrScanTokenPage>{ bool _done=false; final repo=QrRepository(); @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(title: const Text('Quét QR (Token)')), body: MobileScanner(onDetect: (cap) async { if(_done) return; final code = cap.barcodes.isNotEmpty? cap.barcodes.first.rawValue : null; if(code==null) return; String? token; final uri = Uri.tryParse(code); if(uri!=null && uri.queryParameters.containsKey('token')){ token = uri.queryParameters['token']; } else { token = code; } if(token==null || token.isEmpty) return; try{ final res = await repo.resolve(token); final id = res['session_id'] as int?; if(id!=null){ _done=true; if(!mounted) return; Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> CheckInScreen(sessionId: id))); } }catch(e){ if(!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR không hợp lệ: $e'))); } })); }
}
