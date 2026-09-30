import 'package:flutter/material.dart';
import '../constants/styles.dart';

class CustomDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String?)? onChanged;
  final String labelText;
  final IconData icon;
  final String? hintText;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelText,
    required this.icon,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item.isEmpty ? hintText ?? '' : item,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      hint: hintText == null ? null : Text(hintText!),
      isExpanded: true,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: AppStyles.primaryDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppStyles.primaryDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppStyles.primaryDark, width: 2),
        ),
      ),
    );
  }
}
