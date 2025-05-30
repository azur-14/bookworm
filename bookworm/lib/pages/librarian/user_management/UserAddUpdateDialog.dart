import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bookworm/model/User.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserAddUpdateDialog extends StatefulWidget {
  final User? user;
  final void Function(User user) onSubmit;

  const UserAddUpdateDialog({
    Key? key,
    this.user,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _UserAddUpdateDialogState createState() => _UserAddUpdateDialogState();
}

class _UserAddUpdateDialogState extends State<UserAddUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl     = TextEditingController();
  final _emailCtl    = TextEditingController();
  final _phoneCtl    = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool   _passwordVisible = false;
  String _selRole   = 'librarian';
  String _selStatus = 'active';
  String? _base64Avatar;
  String _adminId   = 'unknown_admin';

  final _roles    = ['librarian','customer'];
  final _statuses = ['active','block'];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p){
      setState(()=>_adminId=p.getString('userId')??'unknown_admin');
    });
    if (widget.user!=null) {
      final u=widget.user!;
      _nameCtl.text=u.name;
      _emailCtl.text=u.email;
      _phoneCtl.text=u.phone;
      _passwordCtl.text=u.password;
      _selRole=u.role;
      _selStatus=u.status;
      _base64Avatar=u.avatar;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final img=await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img!=null) {
      final b=await img.readAsBytes();
      setState(()=>_base64Avatar=base64Encode(b));
    }
  }

  Future<String?> _getToken() async {
    final p=await SharedPreferences.getInstance();
    return p.getString('jwt_token');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final isUpdate=widget.user!=null;
    final id=widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final user=User(
      id:id,
      name:_nameCtl.text.trim(),
      email:_emailCtl.text.trim(),
      phone:_phoneCtl.text.trim(),
      password:_passwordCtl.text,
      avatar:_base64Avatar ?? '',
      role:_selRole,
      status:_selStatus,
      timeCreate:widget.user?.timeCreate ?? DateTime.now(),
    );

    try {
      final token=await _getToken();
      final uri=Uri.parse(isUpdate
          ? 'http://localhost:3000/api/users/$id'
          : 'http://localhost:3000/api/users/signup');
      final headers={
        'Content-Type':'application/json',
        if(token!=null) 'Authorization':'Bearer $token'
      };
      final body=jsonEncode(user.toJson());
      final res= isUpdate
          ? await http.put(uri, headers:headers, body:body)
          : await http.post(uri, headers:headers, body:body);
      if (![200,201].contains(res.statusCode)) {
        throw Exception(res.body);
      }
      await http.post(
        Uri.parse('http://localhost:3004/api/logs'),
        headers:{'Content-Type':'application/json'},
        body: jsonEncode({
          'adminId':_adminId,
          'actionType':isUpdate?'UPDATE':'CREATE',
          'targetType':'User',
          'targetId':id,
          'description': isUpdate
              ? 'Cập nhật user ${user.email}'
              : 'Thêm user mới ${user.email}',
        }),
      );
      widget.onSubmit(user);
      Navigator.pop(context);
    } catch(e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg){
    showDialog(
        context:context,
        builder:(_)=>AlertDialog(
          title: const Text('Error',style:TextStyle(color:Colors.red)),
          content: Text(msg),
          actions:[TextButton(
            onPressed:()=>Navigator.pop(context),
            child: const Text('OK'),
          )],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate=widget.user!=null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // header
                Row(
                  children: [
                    Icon(isUpdate?Icons.edit:Icons.person_add,
                        color:AppColors.primary),
                    const SizedBox(width:8),
                    Text(
                      isUpdate ? 'Update User' : 'Add User',
                      style: TextStyle(
                          fontSize:20,
                          fontWeight: FontWeight.bold,
                          color:AppColors.primary
                      ),
                    ),
                  ],
                ),
                const SizedBox(height:24),

                // avatar
                Center(
                  child: Stack(
                      children:[
                        CircleAvatar(
                          radius:48,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: _base64Avatar!=null
                              ? MemoryImage(base64Decode(_base64Avatar!))
                              : null,
                          child: _base64Avatar==null
                              ? Icon(Icons.person, size:48, color:AppColors.primary)
                              : null,
                        ),
                        Positioned(
                          bottom:0,right:0,
                          child: GestureDetector(
                            onTap:_pickAvatar,
                            child: CircleAvatar(
                              radius:16,
                              backgroundColor:AppColors.primary,
                              child: const Icon(Icons.camera_alt,
                                  size:16,color:AppColors.white),
                            ),
                          ),
                        ),
                      ]
                  ),
                ),
                const SizedBox(height:24),

                // form
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key:_formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children:[
                          // name
                          TextFormField(
                            controller: _nameCtl,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              filled: true,                // bật nền
                              fillColor: Colors.white,     // màu nền trắng
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height:16),

                          // email
                          TextFormField(
                            controller:_emailCtl,
                            validator:(v)=>RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(v!)?null:'Invalid email',
                            decoration: InputDecoration(
                              labelText:'Email',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height:16),

                          // phone
                          TextFormField(
                            controller:_phoneCtl,
                            keyboardType: TextInputType.number,
                            validator:(v)=>RegExp(r'^\d{9,12}$').hasMatch(v!)?'Invalid phone':null,
                            decoration: InputDecoration(
                              labelText:'Phone',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.dialpad),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height:16),

                          // password
                          TextFormField(
                            controller:_passwordCtl,
                            obscureText: !_passwordVisible,
                            validator:(v)=>v!.isEmpty?'Required':null,
                            decoration: InputDecoration(
                              labelText:'Password',
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children:[
                                    IconButton(
                                      icon: Icon(_passwordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed:()=>setState(()=>_passwordVisible=!_passwordVisible),
                                      color:AppColors.primary,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed:(){
                                        _passwordCtl.clear();
                                        setState((){});
                                      },
                                      color:AppColors.primary,
                                    ),
                                  ]
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height:16),

                          // role/status side by side
                          Row(
                              children:[
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value:_selRole,
                                    decoration: InputDecoration(
                                      labelText:'Role',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    items:_roles.map((r)=>
                                        DropdownMenuItem(value:r,child:Text(r))
                                    ).toList(),
                                    onChanged:(v)=>setState(()=>_selRole=v!),
                                  ),
                                ),
                                const SizedBox(width:16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value:_selStatus,
                                    decoration: InputDecoration(
                                      labelText:'Status',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    items:_statuses.map((s)=>
                                        DropdownMenuItem(value:s,child:Text(s))
                                    ).toList(),
                                    onChanged:(v)=>setState(()=>_selStatus=v!),
                                  ),
                                ),
                              ]
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height:24),
                // actions
                Row(
                  children:[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          backgroundColor: AppColors.primary,      // nếu muốn nền nâu
                          foregroundColor: AppColors.white,        // text trắng
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: AppColors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width:16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:AppColors.primary,
                          foregroundColor:AppColors.white,
                          shape:RoundedRectangleBorder(
                            borderRadius:BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical:14),
                        ),
                        onPressed:_submit,
                        child: Text(isUpdate?'UPDATE':'ADD'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
