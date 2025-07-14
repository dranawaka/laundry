# Address Fields Implementation for Registration

## Issue
The backend requires address or coordinates for LAUNDRY users, but the registration form didn't include address fields.

**Error Message:**
```
{"timestamp":"2025-07-13T17:47:46.861970399","status":400,"error":"Invalid Argument","message":"Address or coordinates are required for LAUNDRY users","path":"/auth/register"}
```

## Solution
Added comprehensive address fields to the registration form that are required for laundry owners and optional for customers.

## Implementation Details

### 1. Form Fields Added
- **Street Address**: Text input for business address
- **City**: Text input for city name
- **State**: Text input for state/province
- **Zip Code**: Number input for postal code
- **Country**: Text input for country name

### 2. Validation Logic
- **For Laundry Owners**: All address fields are required
- **For Customers**: Address fields are optional (can be left empty)
- **Dynamic Validation**: Address fields only appear and validate when "Laundry Owner" role is selected

### 3. UI/UX Features
- **Conditional Display**: Address section only shows when "Laundry Owner" role is selected
- **Visual Distinction**: Blue-themed container to highlight the business address section
- **Responsive Layout**: City/State and Zip/Country fields are arranged in rows for better space utilization
- **Clear Labeling**: "Business Address (Required for Laundry Owners)" header
- **Icons**: Appropriate icons for each field (home, location_city, map, pin_drop, public)

### 4. API Integration
Updated the `ApiService.register()` method to include address parameters:
```dart
static Future<Map<String, dynamic>> register({
  required String username,
  required String email,
  required String password,
  required String phone,
  required String role,
  String? fcmToken,
  String? address,      // NEW
  String? city,         // NEW
  String? state,        // NEW
  String? zipCode,      // NEW
  String? country,      // NEW
}) async
```

### 5. Backend Request Format
**For Customers:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "password123",
  "role": "CUSTOMER"
}
```

**For Laundry Owners:**
```json
{
  "name": "Clean Laundry Service",
  "email": "business@cleanlaundry.com",
  "phone": "+1234567890",
  "password": "password123",
  "role": "LAUNDRY",
  "address": "123 Business Street",
  "city": "New York",
  "state": "NY",
  "zipCode": "10001",
  "country": "USA"
}
```

## Files Modified

### 1. `lib/registration_screen.dart`
- Added address field controllers
- Added address validation methods
- Added address form fields to UI
- Updated registration call to include address data
- Added conditional display logic for address section

### 2. `lib/api_service.dart`
- Updated `register()` method signature to include address parameters
- Added address fields to request body construction
- Maintained backward compatibility for customers

### 3. `REGISTRATION_FIXES.md`
- Updated documentation to include address fields
- Added API request format examples
- Updated backend requirements

## User Experience

### For Customers
1. Select "Customer" role
2. Fill in basic information (name, email, phone, password)
3. Address fields are hidden (not required)
4. Complete registration

### For Laundry Owners
1. Select "Laundry Owner" role
2. Fill in basic information (name, email, phone, password)
3. Address section appears with blue highlighting
4. Fill in all required address fields
5. Complete registration

## Validation Rules

### Address Validation
- **Street Address**: Required for laundry owners, must not be empty
- **City**: Required for laundry owners, must not be empty
- **State**: Required for laundry owners, must not be empty
- **Zip Code**: Required for laundry owners, must not be empty
- **Country**: Required for laundry owners, must not be empty

### Error Messages
- Clear, specific error messages for each field
- Validation only triggers for laundry owners
- Customers can register without address information

## Testing Scenarios

### ✅ Customer Registration
- [ ] Select Customer role
- [ ] Fill basic fields only
- [ ] Address fields should be hidden
- [ ] Registration should succeed

### ✅ Laundry Owner Registration
- [ ] Select Laundry Owner role
- [ ] Fill basic fields
- [ ] Address section should appear
- [ ] Fill all address fields
- [ ] Registration should succeed

### ✅ Laundry Owner Registration (Missing Address)
- [ ] Select Laundry Owner role
- [ ] Fill basic fields only
- [ ] Leave address fields empty
- [ ] Should show validation errors
- [ ] Registration should fail

### ✅ Role Switching
- [ ] Start with Customer role (no address fields)
- [ ] Switch to Laundry Owner role (address fields appear)
- [ ] Switch back to Customer role (address fields disappear)

## Benefits
1. **Backend Compatibility**: Meets backend requirements for LAUNDRY users
2. **User-Friendly**: Clear visual distinction and helpful labels
3. **Flexible**: Optional for customers, required for business owners
4. **Responsive**: Adapts to different screen sizes
5. **Accessible**: Proper form validation and error messages
6. **Maintainable**: Clean code structure with proper separation of concerns

## Future Enhancements
1. **Address Autocomplete**: Google Places API integration
2. **GPS Coordinates**: Automatic coordinate detection from address
3. **Address Verification**: Real-time address validation
4. **Multiple Addresses**: Support for multiple business locations
5. **Address History**: Save and reuse previous addresses 