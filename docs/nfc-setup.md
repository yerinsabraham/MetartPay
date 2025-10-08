# NFC Tags & Physical Demo Setup Guide

## NFC Tags Specification

### Recommended NFC Tags: NTAG213

**Technical Specifications:**
- **Chip Type:** NTAG213 (NXP)
- **Memory:** 144 bytes user memory
- **Compatibility:** ISO14443 Type A, NFC Forum Type 2
- **Operating Frequency:** 13.56 MHz
- **Read Range:** 1-4cm (depends on device)
- **Data Retention:** 10 years
- **Write/Erase Cycles:** 10,000 cycles

**Physical Specifications:**
- **Size:** 25mm diameter (recommended)  
- **Thickness:** 0.5mm
- **Type:** Adhesive stickers
- **Material:** PVC or PET

### Where to Purchase

**Option 1: Amazon (Recommended)**
- Search: "NTAG213 NFC stickers 25mm"
- **Product:** "NTAG213 NFC Tags Stickers"
- **Quantity:** 30-50 pieces
- **Price Range:** $10-20 USD
- **Delivery:** 2-3 days

**Option 2: Local Electronics Stores**
- **Alaba International Market, Lagos**
- **Computer Village, Lagos** 
- Ask for "NFC tags" or "NTAG213 stickers"

**Option 3: Online Nigerian Stores**
- **Jumia Nigeria**
- **Konga**
- **Slot Nigeria** (check availability)

### Sample Amazon Links (Search Terms)
```
"NTAG213 NFC Tags 25mm Circle"
"NFC Stickers Round NTAG213"  
"Programmable NFC Tags Adhesive"
```

## Merchant Poster Design

### Poster Specifications

**Size:** A4 (210 × 297 mm)
**Design Elements:**
1. **Merchant Business Name** (Large, prominent)
2. **"Tap to Pay" instruction**
3. **QR Code placeholder** (5cm x 5cm)
4. **NFC tag placement area** (Circle, 3cm diameter)
5. **MetartPay branding**
6. **Supported payment methods** (USDT, USDC logos)
7. **Supported networks** (Ethereum, BSC, Solana logos)

### Template Structure
```
┌─────────────────────────────────┐
│        [Business Name]          │
│                                 │
│     💳 TAP TO PAY 💳           │
│                                 │
│  ┌─────┐      ┌─────────────┐   │
│  │ NFC │  OR  │             │   │
│  │ TAG │      │  QR CODE    │   │  
│  │ ⭕  │      │             │   │
│  └─────┘      └─────────────┘   │
│                                 │
│   Accepts: USDT • USDC         │
│   Networks: ETH • BSC • SOL    │
│                                 │
│     Powered by MetartPay        │
└─────────────────────────────────┘
```

## NFC Programming Process

### Tools Needed
1. **Android Phone with NFC** (iPhone can read but not write easily)
2. **NFC Tools App** (Free on Google Play Store)  
3. **NTAG213 Tags**
4. **Printed Posters**

### Programming Steps

**Step 1: Install NFC Tools**
```
Download "NFC Tools" by wakdev from Google Play Store
```

**Step 2: Prepare URLs**
Each merchant will have unique invoice URLs like:
```
https://metartpay.web.app/pay?merchant=MERCHANT_ID
```

**Step 3: Write to NFC Tag**
1. Open NFC Tools app
2. Go to "Write" tab
3. Select "Add a record"
4. Choose "URL/URI"
5. Enter the payment URL
6. Tap "Write" 
7. Hold NFC tag against phone back
8. Wait for "Write successful" message

**Step 4: Test NFC Tag**
1. Use different phone to test
2. Tap tag against phone
3. Verify URL opens correctly
4. Test on both Android and iPhone

### Demo Setup Checklist

**Physical Materials:**
- [ ] 10-20 programmed NFC tags
- [ ] 5-10 printed merchant posters
- [ ] Laminated posters (weather-resistant)
- [ ] Double-sided tape or poster stands
- [ ] Demo table setup materials

**Digital Setup:**
- [ ] Backend deployed and functional
- [ ] Payment URLs responding correctly  
- [ ] QR codes generating properly
- [ ] Mobile app installed on demo devices
- [ ] Wallet apps ready with test funds

**Demo Devices:**
- [ ] Android phone (merchant device)
- [ ] iPhone (buyer device)  
- [ ] Android tablet (optional, for larger display)
- [ ] Portable charger/power bank
- [ ] Backup demo phones

### Testing Scenarios

**Test Case 1: NFC Payment Flow**
1. Merchant creates invoice in app
2. Customer taps NFC tag on poster  
3. Payment page opens in mobile browser
4. Customer completes crypto payment
5. Merchant app shows payment confirmed

**Test Case 2: QR Code Fallback**
1. Customer's phone doesn't support NFC
2. Customer scans QR code instead
3. Same payment flow as NFC
4. Verify both paths work identically

**Test Case 3: Multiple Merchants**
1. Set up 3 different merchant posters
2. Each with unique NFC tag/QR code
3. Verify payments route to correct merchant
4. Test simultaneous payments

### Common Issues & Solutions

**Issue:** NFC tag not reading
- **Solution:** Check NFC enabled in phone settings
- **Solution:** Hold phone closer to tag (1-2cm)
- **Solution:** Remove phone case if thick

**Issue:** Wrong URL opening  
- **Solution:** Reprogram NFC tag with correct URL
- **Solution:** Verify URL format and encoding

**Issue:** Payment page not loading
- **Solution:** Check internet connection
- **Solution:** Verify backend is deployed and running
- **Solution:** Test URL directly in browser

### Production Deployment Notes

**For Live Events:**
- Program tags day before event
- Test all tags individually  
- Bring backup blank tags
- Have NFC programming phone ready
- Print extra posters
- Laminate all materials

**Security Considerations:**
- URLs should use HTTPS only
- Implement rate limiting on payment endpoints  
- Monitor for unusual NFC scanning patterns
- Have backup payment methods ready

**Backup Plans:**
- QR codes always available as fallback
- Manual address copy option
- Direct URL entry method
- SMS-based payment links

### Cost Estimation

**NFC Tags:** $0.50 - $1.00 per tag
**Posters:** $2 - $5 per A4 print + lamination
**Total for 10 merchants:** $25 - $60 USD

**Bulk Pricing (100+ tags):** $0.30 - $0.50 per tag