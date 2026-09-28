
import 'api_service.dart';
class AuthService {
 final ApiService api=ApiService();
 Future<dynamic> roles()=>api.get('/roles');
 Future<dynamic> states()=>api.get('/states');
 Future<dynamic> cities(int stateId)=>api.get('/cities',query:{'stateId':'$stateId'});
 Future<dynamic> login(String email,String password,int roleId,List<int> stateIds,List<int> cityIds,double? lat,double? lng)=>api.post('/auth/login',{'email':email,'password':password,'roleId':roleId,'stateIds':stateIds,'cityIds':cityIds,'lat':lat,'lng':lng});
 Future<dynamic> forgot(String email)=>api.post('/auth/forgot-password',{'email':email});
 Future<dynamic> reset(String email,String otp,String newPassword)=>api.post('/auth/reset-password',{'email':email,'otpCode':otp,'newPassword':newPassword});
}
