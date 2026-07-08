import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neo_parlour/modules/pages/login_screen.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AuthProvider>().fetchUserProfile();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime maxDate = DateTime(now.year - 18, now.month, now.day);
    DateTime initialDate = maxDate;

    if (_dobController.text.isNotEmpty) {
      try {
        final parsed = DateTime.parse(_dobController.text);
        if (parsed.isBefore(maxDate) || parsed.isAtSameMomentAs(maxDate)) {
          initialDate = parsed;
        }
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: maxDate,
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _confirmDelete(AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Delete Account"),
          content: const Text(
            "Are you sure you want to delete your account?\n\nYou have a 30-day grace period to log in and restore your account before it is permanently deleted.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("DELETE"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final success = await auth.deleteUserAccount();

    if (!mounted) return;

    if (success) {      FlushbarHelper.show(context, "Your account has been soft-deleted successfully. You have a 30-day grace period to log in and restore your account before it is permanently deleted.", isSuccess: true);


      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {      FlushbarHelper.show(context, auth.errorMessage ?? "Delete failed");

    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: true,
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            if (auth.errorMessage != null && auth.userProfile == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        auth.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => auth.fetchUserProfile(),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            }

            final profile = auth.userProfile;
            // ⭐ THIS IS THE FIX — keeps controllers synced after navigation
            if (profile != null && !_isEditing) {
              _nameController.text = profile.name;
              _emailController.text = profile.email;
              // Strip country code prefix (+91) so only the 10-digit number is shown
              String phone = profile.phone;
              if (phone.startsWith('+91')) {
                phone = phone.substring(3);
              } else if (phone.startsWith('91') && phone.length > 10) {
                phone = phone.substring(2);
              }
              _phoneController.text = phone;

              if (profile.birthdate != null && profile.birthdate!.isNotEmpty) {
                _dobController.text = profile.birthdate!.split('T')[0];
              }
            }

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).viewPadding.bottom +
                    40,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                  // ================= HEADER =================
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipPath(
                        clipper: EditProfileHeaderClipper(),
                        child: SizedBox(
                          height: size.height * 0.28,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/Images/EditProfileScreen/background_img.jpeg',
                                fit: BoxFit.cover,
                              ),
                              Container(
                                padding: EdgeInsets.only(
                                  left: 20,
                                  bottom: size.height * 0.05,
                                ),
                                alignment: Alignment.bottomLeft,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0XFF8B8B8B).withValues(alpha: 0.4),
                                      const Color(0XFFFF3502).withValues(alpha: 0.85),
                                    ],
                                  ),
                                ),
                                child: const Text(
                                  "EDIT PROFILE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -6,
                        right: 24,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0XFFFF0B01),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              "assets/Images/EditProfileScreen/username_edit_icon.svg",
                              width: 26,
                              height: 26,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        left: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.4),
                            child: const Icon(
                              Icons.chevron_left,
                              size: 30,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ================= CONTENT =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = !_isEditing;
                              });
                            },
                            child: Text(
                              _isEditing ? "CANCEL" : "EDIT",
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            SvgPicture.asset(
                              "assets/Images/EditProfileScreen/username_icon.svg",
                              height: size.width * 0.20,
                            ),
                            Positioned(
                              right: -6,
                              bottom: 4,
                              child: SvgPicture.asset(
                                "assets/Images/EditProfileScreen/username_edit_icon.svg",
                                height: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          profile?.name.toUpperCase() ?? "USER NAME",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildInputField(
                          "assets/Images/EditProfileScreen/enter_name_icon.svg",
                          "Enter Name",
                          controller: _nameController,
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter your name";
                            }
                            if (value.length < 3) {
                              return "Name must be at least 3 characters";
                            }
                            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                              return "Enter a valid name";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        GestureDetector(
                          onTap: _isEditing ? () => _selectDate(context) : null,
                          child: AbsorbPointer(
                            child: _buildInputField(
                              "assets/Images/EditProfileScreen/dob_icon.svg",
                              "Date Of Birth",
                              controller: _dobController,
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null; // optional, but if entered it must be valid
                                }
                                try {
                                  final birthDate = DateTime.parse(value);
                                  final now = DateTime.now();
                                  final ageLimitDate = DateTime(now.year - 18, now.month, now.day);
                                  if (birthDate.isAfter(ageLimitDate)) {
                                    return "Minimum age must be 18 years";
                                  }
                                } catch (_) {
                                  return "Enter a valid date";
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          "assets/Images/DrawerScreen/support_icon.svg", // Using a fallback icon for email
                          "Email",
                          controller: _emailController,
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter your email";
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          "assets/Images/EditProfileScreen/mobile_number_icon.svg",
                          "Mobile Number",
                          controller: _phoneController,
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter mobile number";
                            }
                            if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                              return "Enter valid 10 digit number";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!_isEditing) {
                                return; // prevents action but keeps button active
                              }
                                
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }
                              FocusScope.of(context).unfocus();

                              final updatedData = profile?.toJson() ?? {};
                              updatedData['fullName'] = _nameController.text;
                              // Ensure we send the raw 10-digit number without country code
                              String rawPhone = _phoneController.text.trim();
                              if (rawPhone.startsWith('+91')) {
                                rawPhone = rawPhone.substring(3);
                              } else if (rawPhone.startsWith('91') && rawPhone.length > 10) {
                                rawPhone = rawPhone.substring(2);
                              }
                              updatedData['mobile'] = rawPhone;
                              updatedData['email'] = _emailController.text;

                              if (_dobController.text.isNotEmpty) {
                                updatedData['birthDate'] =
                                    "${_dobController.text}T00:00:00Z";
                              }

                              final success = await auth.updateUserProfile(
                                updatedData,
                              );

                              if (success) {
                                setState(() {
                                  _isEditing = false;
                                });
                                if (context.mounted) {                                  FlushbarHelper.show(context, "Profile updated successfully!", isSuccess: true);

                                }
                              } else {
                                if (context.mounted) {                                  FlushbarHelper.show(context, auth.errorMessage ?? "Update failed",);

                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0XFFFF0B01),
                              disabledBackgroundColor: const Color(0xFFFF0B01),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: auth.isLoadingProfile
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "SAVE",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () => _confirmDelete(auth),
                          child: const Text(
                            "Delete Account",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        SafeArea(top: false, child: const SizedBox(height: 40)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildInputField(
    String icon,
    String hint, {
    required TextEditingController controller,
    required bool enabled,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: TextStyle(
        color: enabled ? Colors.black : Colors.grey.shade600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14),
          child: SvgPicture.asset(
            icon,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              enabled ? const Color(0XFFFF0B01) : Colors.grey,
              BlendMode.srcIn,
            ),
          ),
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0XFF8D8D8D), fontSize: 14),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0XFF909090), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0XFFFF0B01), width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}

class EditProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.65, size.height);
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height,
      size.width,
      size.height * 0.6,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
