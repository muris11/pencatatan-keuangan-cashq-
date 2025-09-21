String? notEmpty(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Required' : null;
String? emailValidator(String? v) =>
    (v == null || !v.contains('@')) ? 'Invalid email' : null;
