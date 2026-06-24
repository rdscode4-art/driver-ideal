import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';

class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData icon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.icon,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  List<Map<String, dynamic>> _predictions = [];
  final FocusNode _focusNode = FocusNode();
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _predictions.isNotEmpty && mounted) {
      setState(() {
        _predictions = [];
      });
    }
  }

  void _onTextChanged() {
    final query = widget.controller.text;
    // Don't search if the query hasn't actually changed (e.g. cursor movement)
    if (query == _lastQuery) return;
    _lastQuery = query;

    if (_focusNode.hasFocus) {
      _searchLocations(query);
    }
  }

  Future<void> _searchLocations(String query) async {
    debugPrint('DEBUG LocationSearch: Searching for "$query"');
    if (query.isEmpty || query.length < 3) {
      if (mounted && _predictions.isNotEmpty) {
        setState(() {
          _predictions = [];
        });
      }
      return;
    }

    try {
      const apiKey = 'AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI';
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$apiKey');
      
      final response = await http.get(url);
      debugPrint('DEBUG LocationSearch: Google API Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint("DEBUG LocationSearch: Google API Status: ${data['status']}");
        
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final List<dynamic> predictionsList = data['predictions'];
          List<Map<String, dynamic>> results = [];
          for (var item in predictionsList) {
            if (item is Map) {
              results.add(Map<String, dynamic>.from(item));
            }
          }
          debugPrint('DEBUG LocationSearch: Found ${results.length} predictions');
          if (mounted) {
            setState(() {
              _predictions = results;
            });
          }
        } else {
          debugPrint('DEBUG LocationSearch: API Response body: ${response.body}');
          if (mounted && _predictions.isNotEmpty) {
            setState(() {
              _predictions = [];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('DEBUG LocationSearch: Error fetching locations: $e');
    }
  }

  InputDecoration _modernInputDecoration() {
    return InputDecoration(
      labelText: widget.labelText,
      labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
      hintText: widget.hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(widget.icon, color: primaryGreen),
      suffixIcon: widget.suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: _modernInputDecoration(),
          validator: widget.validator,
        ),
        if (_predictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _predictions.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> option = _predictions[index];
                final mainText = option['structured_formatting']?['main_text'] ?? option['description'] ?? '';
                final secondaryText = option['structured_formatting']?['secondary_text'] ?? '';
                
                return ListTile(
                  leading: const Icon(Icons.location_on, color: primaryGreen, size: 20),
                  title: Text(
                    mainText,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: secondaryText.isNotEmpty ? Text(
                    secondaryText,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ) : null,
                  onTap: () {
                    // Temporarily remove listener to prevent fetching again
                    widget.controller.removeListener(_onTextChanged);
                    widget.controller.text = option['description'] ?? '';
                    _lastQuery = widget.controller.text;
                    // Move cursor to the end
                    widget.controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: widget.controller.text.length));
                    
                    setState(() {
                      _predictions = [];
                    });
                    _focusNode.unfocus();
                    
                    // Re-add listener after a tiny delay
                    Future.microtask(() {
                       if (mounted) widget.controller.addListener(_onTextChanged);
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
