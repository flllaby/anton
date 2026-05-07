import 'dart:developer';

import 'package:path/path.dart' as p6;
import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

abstract class Identity{
  String get id;
}

class Client implements Identity{
  @override
  final String id;
  final String name;
  final String phone;

  const Client({required this.id, required this.name, required this.phone});

  Map<String, dynamic> toMap()=>{
    'id':id,
    'name':name,
    "phone":phone
  };

  factory Client.fromMap(Map<String,dynamic> map){
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String
    );
  }
  @override
  String toString()=>   "$name ($phone)";
}

class ServiceSalon implements Identity{
  @override
  final String id;
  final String title;
  final int price;
  final int durationTime;

  const ServiceSalon({required this.id,required this.title,required this.price,required this.durationTime,});

  Map<String, dynamic> toMap()=> {
    'id':id,
    'title':title,
    "price":price,
    "durationTime":durationTime
  };

  factory ServiceSalon.fromMap(Map<String,dynamic> map){
    return ServiceSalon(
      id: map['id'] as String,
      title: map['title'] as String,
      price: _asInt (map["price"]),
      durationTime: _asInt( map["durationTime"]),
    );
  }
  static int _asInt(Object? v){
  if(v is int) return v.toInt();
  if(v is num) return v.toInt();
  throw FormatException("Ожидали число",v);
}
  @override
  String toString()=>  "$title-$price руб. (время: $durationTime мин)";
}
class Appointment implements Identity{
  @override
  String id;
  final String clientId;
  final String serviceId;
  final DateTime start;

  Appointment({required this.id,required this.clientId,required this.serviceId,required this.start,});

  Map<String,dynamic> toMap()=> {
    'id':id,
    'clientId':clientId,
    'serviceId':serviceId,
    'start':start.toIso8601String()
  };

  factory Appointment.fromMap(Map<String,dynamic> map){
    return Appointment(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      serviceId: map['serviceId'] as String,
      start: DateTime.parse(map['start'] as String)
    );
  }
  @override
  String toString()=> "запись $id $clientId услуга $serviceId, ${start.toLocal()}";
}
class SalonDatabase{
  Database _sqlite;
  SalonDatabase._(this._sqlite);
  Database get sqlite => _sqlite;

  void _createTable(){
    sqlite.execute('''
        CREATE TABLE IF NOT EXISTS clients(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL
    );
      ''');
  
  sqlite.execute('''
        CREATE TABLE IF NOT EXISTS services(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        price INTEGER NOT NULL,
        durationTime INTEGER NOT NULL
    );
      ''');
  sqlite.execute('''
      CREATE TABLE IF NOT EXISTS appointments(
      id TEXT PRIMARY KEY,
      clientId TEXT NOT NULL,
      serviceId TEXT NOT NULL,
      start TEXT NOT NULL,
      FOREIGN KEY (clientId) REFERENCES clients(id) on DELETE CASCADE,
      FOREIGN KEY (serviceId) REFERENCES services(id) on DELETE CASCADE
    );
      ''');

}
// void close()=>_sqlite.dispose();

static SalonDatabase open({String dataDir = 'data'}) {
    Directory(dataDir).createSync(recursive: true);
    final filePath = p6.join(dataDir, 'salon.db');
    return SalonDatabase._(sqlite3.open(filePath));
  }

  void insrtClient(Client client){
    sqlite.execute('INSERT OR REPLACE INTO clients(id,name,phone) VALUES(?,?,?)', 
    [client.id,client.name,client.phone]);
  }

  List<Client> getAllClient(){
    final result = sqlite.select('SELECT * FROM clients');
    return result.map((row)=>Client.fromMap(row)).toList();
  }

   void insrtService(ServiceSalon service){
    sqlite.execute('INSERT OR REPLACE INTO services(id,title,price,durationTime) VALUES(?,?,?,?)', 
    [service.id,service.title,service.price,service.durationTime]);
  }

  List<ServiceSalon> getAllService(){
    final result = sqlite.select('SELECT * FROM services');
    return result.map((row)=>ServiceSalon.fromMap(row)).toList();
  }

  void insrtAppoinment(Appointment appointment){
    sqlite.execute('INSERT OR REPLACE INTO appointments(id,clientId,serviceId,start) VALUES(?,?,?,?)', 
    [appointment.id,appointment.clientId,appointment.serviceId,appointment.start]);
  }

  List<Appointment> getAllAppointment(){
    final result = sqlite.select('SELECT * FROM appointments');
    return result.map((row)=>Appointment.fromMap(row)).toList();
  }

//--------------------------------------------------------------------------------
  Client? getClient(String id){
    final result = sqlite.select('SELECT * FROM clients WHERE id=?', [id]);
    return result.isNotEmpty ? Client.fromMap(result.first): null;
  }

  void updateClient(Client client){
    sqlite.execute('UPDATE clients SET name=?,phone=? WHERE id=?', [client.id,client.name,client.phone]);
  }

  void deleteClient(String id){
    sqlite.execute('DELETE FROM services WHERE id=?', [id]);
  } 
//--------------------------------------------------------------------------------
  ServiceSalon? getService(String id){
    final result = sqlite.select('SELECT * FROM services WHERE id=?', [id]);
    return result.isNotEmpty ? ServiceSalon.fromMap(result.first): null;
  }
  void updateService(ServiceSalon service){
    sqlite.execute('UPDATE services SET title=?,price=?,durationTime=? WHERE id=?', [service.id,service.title,service.price,service.durationTime]);
  }
  void deleteService(String id){
    sqlite.execute('DELETE FROM services WHERE id=?', [id]);
  } 
//--------------------------------------------------------------------------------
  Appointment? getAppointment(String id){
    final result = sqlite.select('SELECT * FROM appointments WHERE id=?', [id]);
    return result.isNotEmpty ? Appointment.fromMap(result.first): null;
  }
  void updateAppointment(Appointment appointment){
    sqlite.execute('UPDATE appointments SET clientId=?,serviceId=?,start=? WHERE id=?', [appointment.id,appointment.clientId,appointment.serviceId,appointment.start]);
  }
  void deleteAppointment(String id){
    sqlite.execute('DELETE FROM appointment WHERE id=?', [id]);
  }

  void dispose(){
    sqlite.dispose();
  } 
}

void main(){
  SalonDatabase db = SalonDatabase.open(dataDir: './salon.db');
  db._createTable();
  final client = Client(
  id: "1",
  name: "антон",
  phone: "42");

  db.insrtClient(client);
  print(db.getAllClient());
  db.dispose();
}
