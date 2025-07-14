# Role Mapping Fix for Backend Compatibility

## Issue
The Flutter app was sending `LAUNDRY_OWNER` as the role value to the backend, but the Spring Boot backend expects `LAUNDRY` for laundry service providers.

**Error Message:**
```
org.springframework.http.converter.HttpMessageNotReadableException: JSON parse error: Cannot deserialize value of type `com.rr.ldapp.model.Role` from String "LAUNDRY_OWNER": not one of the values accepted for Enum class: [DRIVER, LAUNDRY, CUSTOMER, ADMIN]
```

## Root Cause
The backend Role enum only accepts these values:
- `DRIVER`
- `LAUNDRY` 
- `CUSTOMER`
- `ADMIN`

But the Flutter app was sending `LAUNDRY_OWNER` instead of `LAUNDRY`.

## Solution
Updated the role mapping in both registration and login screens to use the correct backend enum values:

### Before (Incorrect)
```dart
// Registration Screen
_buildRoleCard('LAUNDRY_OWNER', 'Laundry Owner', ...)

// Login Screen  
DropdownMenuItem(value: 'LAUNDRY_OWNER', child: Text('Laundry Owner'))
```

### After (Correct)
```dart
// Registration Screen
_buildRoleCard('LAUNDRY', 'Laundry Owner', ...)

// Login Screen
DropdownMenuItem(value: 'LAUNDRY', child: Text('Laundry Owner'))
```

## Files Modified
1. `lib/registration_screen.dart` - Updated role selection cards
2. `lib/login_screen.dart` - Updated dropdown menu items
3. `REGISTRATION_FIXES.md` - Updated documentation

## Role Mapping Summary
| UI Display | Backend Value | Description |
|------------|---------------|-------------|
| Customer | `CUSTOMER` | Regular users who want to use laundry services |
| Laundry Owner | `LAUNDRY` | Business owners who provide laundry services |

## Testing
- ✅ Registration with Customer role works
- ✅ Registration with Laundry Owner role works  
- ✅ Login with Customer role works
- ✅ Login with Laundry Owner role works
- ✅ Backend receives correct enum values

## Notes
- The UI still displays "Laundry Owner" to users for clarity
- The backend receives `LAUNDRY` as the enum value
- FCM topics and notification topics still use `laundry_owners` (these are different from user roles)
- All other functionality remains unchanged 