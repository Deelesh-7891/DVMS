/// Roles supported by the vehicle-management API.
///
/// Keep this list in sync with the roles issued in the server JWT.  The
/// client uses it for navigation only; the API must still authorize every
/// request from the authenticated token.
enum UserRole {
  corporateAdmin('CorporateAdmin'),
  stateAdmin('StateAdmin'),
  branchAdmin('BranchAdmin'),
  driver('Driver'),
  security('Security'),
  accounts('Accounts');

  const UserRole(this.apiValue);

  final String apiValue;

  static UserRole? fromApiValue(String value) {
    final normalized = value.trim().toLowerCase();
    for (final role in UserRole.values) {
      if (role.apiValue.toLowerCase() == normalized) return role;
    }
    return null;
  }
}
