import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VehiclesScreen extends StatefulWidget { const VehiclesScreen({super.key}); @override State<VehiclesScreen> createState()=>_vehiclesState(); }
class _vehiclesState extends State<VehiclesScreen>{ final api=ApiService(); bool loading=true; String? error; List<dynamic> rows=[];
 @override void initState(){super.initState();load();}
 Future<void> load() async {try{final d=await api.get('/vehicles'); final x=d is Map?(d['data']??d['items']??[]):d; setState((){rows=x is List?x:[x];loading=false;});}catch(e){setState((){error=e.toString();loading=false;});}}
 @override Widget build(BuildContext context){return Scaffold(appBar:AppBar(title:const Text('Vehicles'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),floatingActionButton:FloatingActionButton.extended(onPressed:(){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Create/Edit form will use the Admin Panel API contract here.')));},icon:const Icon(Icons.add),label:const Text('Add')),body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Padding(padding:const EdgeInsets.all(20),child:Text(error!))):rows.isEmpty?const Center(child:Text('No records found')):ListView.builder(padding:const EdgeInsets.all(16),itemCount:rows.length,itemBuilder:(c,i){final r=rows[i];return Card(child:ListTile(title:Text(_title(r)),subtitle:Text(r is Map?r.entries.take(4).map((e)=>'${e.key}: ${e.value}').join(' • '):r.toString())));}));}
 String _title(dynamic r){if(r is Map) return (r['RegistrationNo']??r['FullName']??r['Name']??r['VehicleNo']??r['Title']??'Record').toString(); return 'Record';}
}
