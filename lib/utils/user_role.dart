enum UserRole { user, moderator, admin }

UserRole parseRole(String role) {
  switch (role) {
    case "admin":
      return UserRole.admin;
    case "moderator":
      return UserRole.moderator;
    default:
      return UserRole.user;
  }
}
