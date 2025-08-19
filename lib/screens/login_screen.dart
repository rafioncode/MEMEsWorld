import 'package:flutter/material.dart';
import 'package:memesworld/resources/auth_methods.dart';
import 'package:memesworld/responsive/mobile_screen_layout.dart';
import 'package:memesworld/responsive/responsive_layout.dart';
import 'package:memesworld/responsive/web_screen_layout.dart';
import 'package:memesworld/screens/signup_screen.dart';
import 'package:memesworld/utils/colors.dart';
import 'package:memesworld/utils/global_variable.dart';
import 'package:memesworld/utils/utils.dart';
import 'package:memesworld/widgets/text_field_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    final String res = await AuthMethods().loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (res == 'success') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const ResponsiveLayout(
            mobileScreenLayout: MobileScreenLayout(),
            webScreenLayout: WebScreenLayout(),
          ),
        ),
            (route) => false,
      );
    } else {
      showSnackBar(context, res);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          padding: screenWidth > webScreenSize
              ? EdgeInsets.symmetric(horizontal: screenWidth / 3)
              : const EdgeInsets.symmetric(horizontal: 32),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.25,
                width: double.infinity,
                alignment: Alignment.center,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double imageWidth = constraints.maxWidth * 0.5;
                    if (imageWidth > 350) imageWidth = 350;
                    if (imageWidth < 180) imageWidth = 180;

                    return Image.asset(
                      'assets/images/memesworld.png',
                      color: primaryColor,
                      width: imageWidth,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20), // space after logo

              TextFieldInput(
                hintText: 'Enter your email',
                textInputType: TextInputType.emailAddress,
                textEditingController: _emailController,
              ),
              SizedBox(height: screenWidth * 0.03),

              TextFieldInput(
                hintText: 'Enter your password',
                textInputType: TextInputType.text,
                textEditingController: _passwordController,
                isPass: true,
              ),
              SizedBox(height: screenWidth * 0.03),

              InkWell(
                onTap: _isLoading ? null : loginUser,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    color: blueColor,
                  ),
                  child: !_isLoading
                      ? const Text('Log in')
                      : const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                ),
              ),

              SizedBox(height: screenWidth * 0.02),
              const Spacer(flex: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        ' Signup.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
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
