# Dynamic SOAP-to-REST Routing

## Convention-Based Approach

แทนที่จะ hardcode mapping ทุก endpoint, ระบบจะใช้ **naming convention** ในการกำหนด HTTP method และ path โดยอัตโนมัติ

## Naming Convention

### Operation Name Pattern
```
{action}{Resource}Request
```

### Supported Actions

| Action Prefix | HTTP Method | Needs ID | Example Operation | REST Endpoint |
|--------------|-------------|----------|-------------------|---------------|
| `get`        | GET         | ✅ Yes   | `getUserRequest`  | `GET /users/{id}` |
| `list`       | GET         | ❌ No    | `listUsersRequest` | `GET /users` |
| `create`     | POST        | ❌ No    | `createUserRequest` | `POST /users` |
| `update`     | PUT         | ✅ Yes   | `updateUserRequest` | `PUT /users/{id}` |
| `delete`     | DELETE      | ✅ Yes   | `deleteUserRequest` | `DELETE /users/{id}` |

## Examples

### 1. Get User (GET with ID)
**SOAP Request:**
```xml
<wsdl:getUserRequest>
   <wsdl:id>1</wsdl:id>
</wsdl:getUserRequest>
```
**→ Converts to:** `GET /users/1`

---

### 2. Create User (POST)
**SOAP Request:**
```xml
<wsdl:createUserRequest>
   <wsdl:name>John</wsdl:name>
   <wsdl:email>john@example.com</wsdl:email>
</wsdl:createUserRequest>
```
**→ Converts to:** `POST /users` with JSON body:
```json
{"name": "John", "email": "john@example.com"}
```

---

### 3. Update User (PUT with ID)
**SOAP Request:**
```xml
<wsdl:updateUserRequest>
   <wsdl:id>1</wsdl:id>
   <wsdl:name>John Updated</wsdl:name>
</wsdl:updateUserRequest>
```
**→ Converts to:** `PUT /users/1` with JSON body:
```json
{"name": "John Updated"}
```

---

### 4. Delete User (DELETE with ID)
**SOAP Request:**
```xml
<wsdl:deleteUserRequest>
   <wsdl:id>1</wsdl:id>
</wsdl:deleteUserRequest>
```
**→ Converts to:** `DELETE /users/1`

---

### 5. List Users (GET without ID)
**SOAP Request:**
```xml
<wsdl:listUsersRequest/>
```
**→ Converts to:** `GET /users`

---

## Adding New Resources

**ไม่ต้อง hardcode อะไรเพิ่ม!** แค่ตั้งชื่อ operation ตาม convention:

### Example: Products Resource

```xml
<!-- Get Product -->
<wsdl:getProductRequest>
   <wsdl:id>123</wsdl:id>
</wsdl:getProductRequest>
<!-- → GET /products/123 -->

<!-- Create Product -->
<wsdl:createProductRequest>
   <wsdl:name>Laptop</wsdl:name>
   <wsdl:price>999</wsdl:price>
</wsdl:createProductRequest>
<!-- → POST /products -->

<!-- Update Product -->
<wsdl:updateProductRequest>
   <wsdl:id>123</wsdl:id>
   <wsdl:price>899</wsdl:price>
</wsdl:updateProductRequest>
<!-- → PUT /products/123 -->

<!-- Delete Product -->
<wsdl:deleteProductRequest>
   <wsdl:id>123</wsdl:id>
</wsdl:deleteProductRequest>
<!-- → DELETE /products/123 -->

<!-- List Products -->
<wsdl:listProductsRequest/>
<!-- → GET /products -->
```

## Response Conversion

JSON response จะถูกแปลงเป็น XML **แบบ dynamic** โดยไม่ต้อง hardcode structure:

**JSON Response:**
```json
{
  "id": "1",
  "name": "John",
  "email": "john@example.com",
  "active": true
}
```

**→ XML Response:**
```xml
<wsdl:getUserResponse>
   <id>1</id>
   <name>John</name>
   <email>john@example.com</email>
   <active>true</active>
</wsdl:getUserResponse>
```

## Configuration

หาก convention ไม่เพียงพอ สามารถ customize ได้ที่ `config` object ใน `soap_proxy.lua`:

```lua
local config = {
    base_path = "/internal_rest_proxy",
    action_patterns = {
        -- เพิ่ม action ใหม่ได้ที่นี่
        search = {method = ngx.HTTP_GET, needs_id = false},
        patch = {method = ngx.HTTP_PATCH, needs_id = true},
    }
}
```
