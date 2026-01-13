# Testing Shop Endpoints (ไม่ต้องแก้ soap_proxy.lua!)

## 1. Get Shop (GET /shops/:id)

**SOAP Request:**
```xml
POST http://localhost:8080/wsdl
Content-Type: text/xml

<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsdl="http://www.examples.com/wsdl/UserService.wsdl">
   <soapenv:Header/>
   <soapenv:Body>
      <wsdl:getShopRequest>
         <wsdl:id>1</wsdl:id>
      </wsdl:getShopRequest>
   </soapenv:Body>
</soapenv:Envelope>
```

**Expected Response:**
```xml
<soapenv:Envelope ...>
   <soapenv:Body>
      <wsdl:getShopResponse>
         <name>Coffee Shop</name>
         <location>Bangkok</location>
      </wsdl:getShopResponse>
   </soapenv:Body>
</soapenv:Envelope>
```

---

## 2. Create Shop (POST /shops)

**SOAP Request:**
```xml
POST http://localhost:8080/wsdl
Content-Type: text/xml

<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsdl="http://www.examples.com/wsdl/UserService.wsdl">
   <soapenv:Header/>
   <soapenv:Body>
      <wsdl:createShopRequest>
         <wsdl:name>Pizza Place</wsdl:name>
         <wsdl:location>Phuket</wsdl:location>
      </wsdl:createShopRequest>
   </soapenv:Body>
</soapenv:Envelope>
```

**Expected Response:**
```xml
<soapenv:Envelope ...>
   <soapenv:Body>
      <wsdl:createShopResponse>
         <id>3</id>
         <status>Success</status>
      </wsdl:createShopResponse>
   </soapenv:Body>
</soapenv:Envelope>
```

---

## 3. List Shops (GET /shops)

**SOAP Request:**
```xml
POST http://localhost:8080/wsdl
Content-Type: text/xml

<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsdl="http://www.examples.com/wsdl/UserService.wsdl">
   <soapenv:Header/>
   <soapenv:Body>
      <wsdl:listShopsRequest/>
   </soapenv:Body>
</soapenv:Envelope>
```

**Expected Response:**
```xml
<soapenv:Envelope ...>
   <soapenv:Body>
      <wsdl:listShopsResponse>
         <shops>
            <id>1</id>
            <name>Coffee Shop</name>
            <location>Bangkok</location>
         </shops>
         <shops>
            <id>2</id>
            <name>Book Store</name>
            <location>Chiang Mai</location>
         </shops>
      </wsdl:listShopsResponse>
   </soapenv:Body>
</soapenv:Envelope>
```

---

## การทำงาน

1. **OpenResty Lua** จะดักจับ `getShopRequest` → แยก action=`get`, resource=`Shop`
2. แปลง path → `/shops/1`
3. ยิง `GET /shops/1` ไปที่ REST API
4. รับ JSON response กลับมา → แปลงเป็น XML
5. Return `<getShopResponse>...</getShopResponse>`

**🎯 ไม่ต้องแก้ `soap_proxy.lua` เลย!** มันทำงานแบบ convention-based

---

## Direct REST API Test (สำหรับเช็คว่า REST API ทำงาน)

```bash
# GET Shop
curl http://localhost:3000/shops/1

# Create Shop
curl -X POST http://localhost:3000/shops \
  -H "Content-Type: application/json" \
  -d '{"name":"Ramen House","location":"Pattaya"}'

# List Shops
curl http://localhost:3000/shops
```
