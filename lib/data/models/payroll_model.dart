class PayrollModel {
  final int id;
  final int userId;
  final String month; // YYYY-MM
  final double baseSalary;
  final double allowances; // housing, transport, etc
  final double deductions; // gosi, lmra, etc
  final double incentives;
  final double netSalary;
  final String status; // pending, paid

  PayrollModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    required this.incentives,
    required this.netSalary,
    required this.status,
  });

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    return PayrollModel(
      id: json['id'],
      userId: json['user_id'],
      month: json['month'],
      baseSalary: (json['base_salary'] as num).toDouble(),
      allowances: (json['allowances'] as num).toDouble(),
      deductions: (json['deductions'] as num).toDouble(),
      incentives: (json['incentives'] as num).toDouble(),
      netSalary: (json['net_salary'] as num).toDouble(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'month': month,
      'base_salary': baseSalary,
      'allowances': allowances,
      'deductions': deductions,
      'incentives': incentives,
      'net_salary': netSalary,
      'status': status,
    };
  }
}
