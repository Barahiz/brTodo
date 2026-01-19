import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();
    
    final theme = Theme.of(context);
    
    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isError) 
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.info_outline, color: Colors.white70),
              ),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: isError 
          ? Color.fromRGBO(60, 60, 60, 0.95)  // Dark gray with slight transparency
          : theme.primaryColor.withOpacity(0.95),
        elevation: 4,
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white70,
          onPressed: () => scaffold.hideCurrentSnackBar(),
        ),
      ),
    );
  }

  String _handleFirebaseError(FirebaseAuthException e) {
    print('Firebase error code: ${e.code}');  // For debugging
    
    switch (e.code) {
      case 'user-not-found':
        return 'We couldn\'t find an account with this email. Need to create one?';
        
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
        
      case 'invalid-credential':
        return 'Please check your email and password and try again.';
        
      case 'invalid-email':
        return 'Please enter a valid email address.';
        
      case 'email-already-in-use':
        return 'This email is already registered. Would you like to login instead?';
        
      case 'weak-password':
        return 'Your password should be at least 6 characters long.';
        
      case 'too-many-requests':
        return 'Too many attempts. Please try again in a few minutes.';
        
      case 'network-request-failed':
        return 'Connection issues detected. Please check your internet connection.';
        
      case 'operation-not-allowed':
        return 'Unable to process your request. Please contact support.';
        
      default:
        print('Unhandled Firebase error: ${e.code} - ${e.message}');
        return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } else {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String errorMessage = _handleFirebaseError(e);
          _showToast(context, errorMessage, isError: true);
          
          // Clear password field on specific errors
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            _passwordController.clear();
          }
          
          // Clear both fields for user not found
          if (e.code == 'user-not-found') {
            _passwordController.clear();
          }
        }
      } catch (e) {
        if (mounted) {
          _showToast(
            context, 
            'Unable to process your request. Please try again.',
            isError: true
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 24),
                        Text(
                          _isLogin ? 'Welcome Back!' : 'Create Account',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator()
                                : Text(
                                    _isLogin ? 'Login' : 'Sign Up',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin
                                ? 'Need an account? Sign up'
                                : 'Have an account? Login',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}