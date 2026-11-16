# 🛍️ MEAW E-Commerce Backend (Dart Frog + MongoDB + Bakong KHQR)

A complete e-commerce REST API built with **Dart Frog**, **MongoDB (NoSQL)**, and **Bakong KHQR** digital payments, faithfully implementing the [Figma ML E-Commerce Design](https://www.figma.com/design/rkL3Ge6aEVFJds97XDSOb3/ML-E-Commerce?node-id=283-4802).

> 🌐 **All Endpoints**: Use direct URL `http://localhost:8080` (no variables like `{{baseUrl}}` required).  
> 💳 **Account Followed**: `LYHAV VOEURN` (`lyhav_voeurn@bkrt`, `+855 67 687 806`, Bank: `Bakong`).  
> 🏷️ **Product KHQR**: Every product in the store has its own embedded, pre-generated scannable KHQR code matching its exact price.  
> 📱 **Interactive Web Simulator**: Open [http://localhost:8080/screens](http://localhost:8080/screens) to test the live mobile screens and product QR codes in your browser.

---

## 📱 Figma Mobile Screen Mapping

| Screen # | Screen Name | Visual Design Elements | Primary API Endpoints | MongoDB Collection |
| :--- | :--- | :--- | :--- | :--- |
| **Screen 1** | **Sign Up (`singin`)** | Cartoon mascot, "Welcome! Let's get start", Name, Email, Password, Terms Checkbox | `POST http://localhost:8080/api/v1/auth/signup` | `users`, `sessions` |
| **Screen 2** | **Login** | "Welcome!", Email (`Sethi@gmail.com`), Password, Forgot Password, Social logins | `POST http://localhost:8080/api/v1/auth/login` | `users`, `sessions` |
| **Screen 3** | **Empty Bag** | "YOUR BAG SHOPPING CART", "Your cart is empty", 5-tab Bottom Navigation | `GET http://localhost:8080/api/v1/cart` | `carts` |
| **Screen 4** | **Shopping Cart** | Multi-product items, Qty Stepper `[- 1 +]`, Payment Method (COD / Digital KHQR), Promo Code, Subtotal, Total, "Proceed to checkout >" | `GET http://localhost:8080/api/v1/cart`<br>`PUT http://localhost:8080/api/v1/cart/update`<br>`POST http://localhost:8080/api/v1/cart/promo`<br>`POST http://localhost:8080/api/v1/payments` | `carts`<br>`orders`<br>`payments` |
| **Screen 5** | **Product & Buy Now** | "GOODY BLESSED MOON", "1+1 FREE ON BLESSED MOON AURA CREAM", $40.00 USD, `[- 1 +]`, **[Add to bag]** (Black), **[Buy now]** (Green), **[View Product KHQR]** | `GET http://localhost:8080/api/v1/products/:id`<br>`POST http://localhost:8080/api/v1/cart/add`<br>`POST http://localhost:8080/api/v1/payments` | `products`<br>`carts`<br>`orders`<br>`payments` |
| **Screen 6** | **Profile ("Me") & Logout** | "Roth Sethi", `Sethi@gmail.com`, Personal Info, My Order, Address, Payment Method, Setting, Help & Support, **Logout** | `GET http://localhost:8080/api/v1/auth/me`<br>`GET http://localhost:8080/api/v1/orders`<br>`POST http://localhost:8080/api/v1/auth/logout` | `users`<br>`orders`<br>`sessions` |
| **Screen 7 & 8**| **Home & Explore Catalog** | Search bar, Category tabs (Fashion, Beauty, Electronics, Watches), Trading Now (Linin Body Cream $24, WEYOUNG $30) with `[+ Bag]`, `[Buy]`, `[QR]` | `GET http://localhost:8080/api/v1/products`<br>`GET http://localhost:8080/api/v1/products?category=Beauty` | `products` |

---

## 🗄️ MongoDB Collections Architecture

```mermaid
erDiagram
    users ||--o{ sessions : "has active"
    users ||--o| carts : "owns"
    users ||--o{ orders : "places"
    orders ||--o{ payments : "triggers KHQR"
    products ||--o{ carts : "item reference"
    products ||--o{ orders : "item snapshot"

    users {
        ObjectId _id PK
        string name "Roth Sethi"
        string email "Sethi@gmail.com"
        string passwordHash "SHA-256 salted hash"
        string phone "+855 12 345 678"
        string address "Street 2004, Phnom Penh"
        string avatarUrl "Profile image"
        date createdAt
    }
    products {
        ObjectId _id PK
        string name "Aura Cream 1+1"
        string category "Beauty"
        string brand "GOODY BLESSED MOON"
        double price "40.00"
        string currency "USD"
        double rating "4.9"
        int reviewCount "128"
        string tag "1+1 FREE"
        bool isFlash false
        string khqr "EMVCo Bakong string for LYHAV VOEURN"
        string md5 "Transaction MD5 hash"
        string qrImageUrl "500x500 high-density scannable QR"
        string qrImageUrlFallback "QuickChart fallback QR"
        string bakongAccountId "lyhav_voeurn@bkrt"
        string merchantName "LYHAV VOEURN"
    }
    carts {
        ObjectId _id PK
        string userId FK
        array items "List of CartItem (productId, name, price, qty, subtotal)"
        string promoCode "DISCOUNT10"
        double discount "10.0"
        double subtotal "40.0"
        double shippingFee "0.0 (Free)"
        double total "40.0"
        date updatedAt
    }
    orders {
        ObjectId _id PK
        string orderNumber "ORD-1731219200000"
        string userId FK
        string customerName "Roth Sethi"
        string customerEmail "Sethi@gmail.com"
        array items "Purchased CartItems"
        double totalAmount "40.00"
        string currency "USD"
        string paymentMethod "digital_payment / cash_on_delivery"
        string paymentStatus "PENDING / PAID / COD_PENDING"
        string orderStatus "PLACED"
        string khqr "EMVCo KHQR string"
        string md5 "Transaction MD5 hash"
        string qrImageUrl "Rendered QR code image URL"
        string qrImageUrlFallback "High-res fallback QR"
        date createdAt
    }
    payments {
        ObjectId _id PK
        string md5 "Unique Bakong MD5 hash"
        string qr "EMVCo compliant string"
        string qrImageUrl "500x500 crisp QR image"
        double amount "40.00"
        string currency "USD"
        string bakongAccountId "lyhav_voeurn@bkrt"
        string merchantName "LYHAV VOEURN"
        string billNumber "PRD-AuraCream / ORD-1731..."
        string status "PENDING / PAID"
        string orderId FK
        string productId FK
        date createdAt
    }
    sessions {
        ObjectId _id PK
        string token "Bearer session token"
        string userId FK
        string email "Sethi@gmail.com"
        bool isActive true
        date expiresAt
    }
```

---

## ⚡ Quick Start

### 1. Requirements
* **Dart SDK** `^3.11.0`
* **Dart Frog CLI**: `dart pub global activate dart_frog_cli`
* **MongoDB**: Running at `mongodb://127.0.0.1:27017` (database `api`)

### 2. Run MongoDB & API
```powershell
# 1. Start MongoDB (if not running as a Windows service)
mongod --dbpath "C:\data\db"

# 2. Start Dart Frog Server on Port 8080
dart_frog dev
```
Server runs on: **`http://localhost:8080`**

---

## 🧪 Testing Flow Step-by-Step (Follows Your Screens)

### Step 1: Sign Up (`singin`) — Screen 1
* **Method**: `POST`
* **URL**: `http://localhost:8080/api/v1/auth/signup`
* **Headers**: `Content-Type: application/json`
* **Body**:
  ```json
  {
    "name": "Roth Sethi",
    "email": "Sethi@gmail.com",
    "password": "Password123!",
    "phone": "+855 12 345 678",
    "address": "Street 2004, Phnom Penh, Cambodia"
  }
  ```
* **Response (201 Created)**: Returns `{ "success": true, "token": "...", "user": { ... } }`.
* **Postman Script**: Automatically sets `{{auth_token}}`.

---

### Step 2: Login (with JWT Token) — Screen 2
* **Method**: `POST`
* **URL**: `http://localhost:8080/api/v1/auth/login`
* **Headers**: `Content-Type: application/json`
* **Body**:
  ```json
  {
    "email": "Sethi@gmail.com",
    "password": "Password123!"
  }
  ```
* **Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Login successful",
    "token_type": "Bearer",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 2592000,
    "user": {
      "id": "6730623...",
      "name": "Roth Sethi",
      "email": "sethi@gmail.com"
    }
  }
  ```

---

### Step 3: Browse Catalog & Products with Embedded KHQR — Screens 7 & 8
Seed default Figma products:
* `POST http://localhost:8080/api/v1/products/seed`

List all products:
* `GET http://localhost:8080/api/v1/products`

Every product returned from MongoDB contains its **pre-generated Bakong KHQR** code for account `LYHAV VOEURN`:
```json
{
  "success": true,
  "count": 6,
  "data": [
    {
      "id": "6730629a...",
      "name": "Aura Cream 1+1",
      "description": "1+1 FREE on Blessed Moon Aura Cream. Deep hydration and glow effect.",
      "price": 40.0,
      "currency": "USD",
      "category": "Beauty",
      "brand": "GOODY BLESSED MOON",
      "rating": 4.9,
      "reviewCount": 128,
      "tag": "1+1 FREE",
      "khqr": "00020101021229440017lyhav_voeurn@bkrt01090676878060206Bakong520459995303840540540.005802KH5912LYHAV VOEURN6010Phnom Penh62270113PRD-AuraCream0211855676878066304...",
      "md5": "0b48c66e944b2f6ef1e464c489704c32",
      "qrImageUrl": "https://api.qrserver.com/v1/create-qr-code/?size=500x500&margin=2&ecc=M&data=00020101021229440017lyhav_voeurn%40bkrt...",
      "qrImageUrlFallback": "https://quickchart.io/qr?size=500&margin=2&ecLevel=M&text=00020101021229440017lyhav_voeurn%40bkrt...",
      "bakongAccountId": "lyhav_voeurn@bkrt",
      "merchantName": "LYHAV VOEURN"
    },
    {
      "id": "6730629b...",
      "name": "Linin Body Cream",
      "price": 24.0,
      "currency": "USD",
      "khqr": "00020101021229440017lyhav_voeurn@bkrt01090676878060206Bakong520459995303840540524.005802KH5912LYHAV VOEURN6010Phnom Penh...",
      "md5": "12f9d8a...",
      "qrImageUrl": "https://api.qrserver.com/v1/create-qr-code/?size=500x500&margin=2&ecc=M&data=..."
    }
  ]
}
```

---

### Step 4: Add to Bag & Shopping Cart — Screens 3 & 4
Users can add **ANY product** to their bag. The cart reflects whatever items are actually added, computing real-time item quantities, subtotals, and discounts, **without any hardcoded auto-selection**.

#### A. Add Products to Bag
* `POST http://localhost:8080/api/v1/cart/add` with `{"productId": "Aura Cream 1+1", "quantity": 1}`
* `POST http://localhost:8080/api/v1/cart/add` with `{"productId": "Linin Body Cream", "quantity": 1}`
* `POST http://localhost:8080/api/v1/cart/add` with `{"productId": "WEYOUNG Facial Essence", "quantity": 1}`

#### B. View Shopping Cart (`GET http://localhost:8080/api/v1/cart`)
**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "itemCount": 3,
    "items": [
      {
        "productId": "6730629a...",
        "name": "Aura Cream 1+1",
        "category": "Beauty",
        "price": 40.0,
        "currency": "USD",
        "quantity": 1,
        "subtotal": 40.0
      },
      {
        "productId": "6730629b...",
        "name": "Linin Body Cream",
        "category": "Beauty",
        "price": 24.0,
        "currency": "USD",
        "quantity": 1,
        "subtotal": 24.0
      },
      {
        "productId": "6730629c...",
        "name": "WEYOUNG Facial Essence",
        "category": "Beauty",
        "price": 30.0,
        "currency": "USD",
        "quantity": 1,
        "subtotal": 30.0
      }
    ],
    "subtotal": 94.0,
    "shippingFee": 0.0,
    "discount": 0.0,
    "total": 94.0
  }
}
```

#### C. Update Quantity, Promo, Remove
* Update: `PUT http://localhost:8080/api/v1/cart/update` with `{"productId": "Aura Cream 1+1", "quantity": 2}`
* Promo: `POST http://localhost:8080/api/v1/cart/promo` with `{"promoCode": "DISCOUNT10"}`
* Remove: `POST http://localhost:8080/api/v1/cart/remove` with `{"productId": "Linin Body Cream"}`

---

### Step 5: Buy Now via `http://localhost:8080/api/v1/payments` — Screen 5
Directly buy any product using `POST http://localhost:8080/api/v1/payments`. It calculates the price, places the order, creates the payment record, and returns a 100% scannable Bakong KHQR QR code.

* **Method**: `POST`
* **URL**: `http://localhost:8080/api/v1/payments`
* **Headers**: `Content-Type: application/json`, `Authorization: Bearer {{auth_token}}`
* **Body**:
  ```json
  {
    "productId": "Aura Cream 1+1",
    "quantity": 1,
    "paymentMethod": "digital_payment",
    "deliveryAddress": "Street 2004, Phnom Penh, Cambodia"
  }
  ```
* **Response (201 Created)**:
  ```json
  {
    "success": true,
    "message": "Payment generated successfully for Buy Now",
    "data": {
      "paymentId": "6730691...",
      "orderId": "6730691...",
      "orderNumber": "ORD-1731221800000",
      "customerName": "Roth Sethi",
      "amount": 40.0,
      "currency": "USD",
      "bakongAccountId": "lyhav_voeurn@bkrt",
      "merchantName": "LYHAV VOEURN",
      "billNumber": "ORD-1731221800000",
      "status": "PENDING",
      "qr": "00020101021229440017lyhav_voeurn@bkrt01090676878060206Bakong520459995303840540540.005802KH5912LYHAV VOEURN6010Phnom Penh62360117ORD-17312218000000211855676878066304...",
      "md5": "0b48c66e944...",
      "qrImageUrl": "https://api.qrserver.com/v1/create-qr-code/?size=500x500&margin=2&ecc=M&data=00020101021229440017lyhav_voeurn%40bkrt...",
      "qrImageUrlFallback": "https://quickchart.io/qr?size=500&margin=2&ecLevel=M&text=00020101021229440017lyhav_voeurn%40bkrt...",
      "orderStatus": "PLACED",
      "paymentStatus": "PENDING"
    }
  }
  ```

---

### Step 6: Checkout Cart via `http://localhost:8080/api/v1/payments` — Screen 4
Converts all items in the shopping cart into an order, automatically empties the cart, and returns the scannable KHQR payment code.

* **Method**: `POST`
* **URL**: `http://localhost:8080/api/v1/payments`
* **Headers**: `Content-Type: application/json`, `Authorization: Bearer {{auth_token}}`
* **Body**:
  ```json
  {
    "fromCart": true,
    "paymentMethod": "digital_payment",
    "deliveryAddress": "Street 2004, Phnom Penh, Cambodia",
    "promoCode": "DISCOUNT10"
  }
  ```

---

### Step 7: Profile ("Me") & Orders — Screen 6
* **View Profile (Roth Sethi)**: `GET http://localhost:8080/api/v1/auth/me`
* **Update Profile**: `PUT http://localhost:8080/api/v1/auth/me`
* **List My Orders**: `GET http://localhost:8080/api/v1/orders`
* **Get Order by ID**: `GET http://localhost:8080/api/v1/orders/{{order_id}}`

---

### Step 8: Logout — Screen 6
* **Method**: `POST`
* **URL**: `http://localhost:8080/api/v1/auth/logout`
* **Headers**: `Authorization: Bearer {{auth_token}}`, `Content-Type: application/json`
* **Body**: `{"token": "{{auth_token}}"}`

---

### Step 9: Verify Bakong KHQR Payment
* **Method**: `POST`
* **URL**: `http://localhost:8080/api/v1/payments/verify`
* **Body**: `{"md5": "{{last_md5}}"}` or `{"md5": "{{product_md5}}"}`
* **Response**:
  ```json
  {
    "success": true,
    "status": "PENDING",
    "isPaid": false,
    "message": "Transaction not found or pending scan",
    "payment": { ... }
  }
  ```
When paid in Bakong/ABA app, `status` automatically flips to `PAID`, records `transactionHash`, and marks order `PAID`!

---

## 🔍 Bakong KHQR EMVCo Scannability Specifications

The KHQR codes generated for your account follow the official National Bank of Cambodia (NBC) EMVCo standard:

| Tag | Field Name | Format | Value in MEAW API |
| :--- | :--- | :--- | :--- |
| **`00`** | Payload Format Indicator | `000201` | Version `01` |
| **`01`** | Point of Initiation | `010212` | `12` (Dynamic with pre-filled amount) |
| **`29`** | Merchant Account Info | `2944...` | Tag 29 for Individual: `00` (Account ID: `lyhav_voeurn@bkrt`), `01` (Phone: `067687806`), `02` (Acquiring Bank: `Bakong`) |
| **`52`** | Merchant Category Code | `52045999` | `5999` (Individual / Solo Retail) |
| **`53`** | Transaction Currency | `5303840` | `840` for USD (`116` for KHR) |
| **`54`** | Transaction Amount | `540540.00` | 2 decimal places for USD (e.g. `40.00`) |
| **`58`** | Country Code | `5802KH` | `KH` (Cambodia) |
| **`59`** | Merchant Name | `5912LYHAV VOEURN` | `LYHAV VOEURN` |
| **`60`** | Merchant City | `6010Phnom Penh` | `Phnom Penh` |
| **`62`** | Additional Data Field | `6236...` | Sub-tag `01` (Bill/Order Number), Sub-tag `02` (Mobile: `85567687806`), Sub-tag `03` (`MEAW Store`), Sub-tag `07` (`Catalog`) |
| **`63`** | Checksum (CRC16) | `6304XXXX` | CRC-16/CCITT-FALSE (`poly: 0x1021`, `init: 0xFFFF`) |

### QR Image Rendering
* **Size**: `500x500` pixels
* **Margin (Quiet Zone)**: `margin=2` (ensures QR code fills the image and is instantly recognized by phone cameras)
* **Error Correction**: `ecc=M` (15% error recovery for crisp, fast scanning)
* **Fallback URL**: Provides both `api.qrserver.com` and `quickchart.io` URLs in the response.

