import 'dart:io';
import 'package:api/config/app_config.dart';
import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  final config = context.read<AppConfig>();

  final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Bakong KHQR Test Scanner - ${config.appName}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
    body { background-color: #f1f5f9; display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 20px; }
    .khqr-card { width: 100%; max-width: 380px; background: white; border-radius: 20px; box-shadow: 0 15px 35px rgba(0,0,0,0.12); overflow: hidden; text-align: center; }
    .header { background: #E12229; color: white; padding: 20px 16px; position: relative; }
    .header h2 { font-size: 20px; font-weight: 700; letter-spacing: 1px; }
    .header p { font-size: 13px; opacity: 0.9; margin-top: 4px; }
    .content { padding: 24px 20px; }
    .merchant-name { font-size: 18px; font-weight: 700; color: #1e293b; text-transform: uppercase; }
    .account-id { font-size: 13px; color: #64748b; margin-top: 4px; }
    .amount-display { margin: 16px 0; font-size: 26px; font-weight: 800; color: #E12229; }
    .qr-container { background: #fafafa; border: 2px dashed #cbd5e1; border-radius: 16px; padding: 16px; display: inline-block; margin-bottom: 16px; }
    .qr-container img { width: 220px; height: 220px; display: block; border-radius: 8px; }
    .controls { display: flex; gap: 8px; justify-content: center; margin-bottom: 16px; }
    .btn { padding: 8px 14px; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; border: none; transition: 0.2s; }
    .btn-outline { background: #f8fafc; border: 1px solid #cbd5e1; color: #475569; }
    .btn-outline.active { background: #E12229; color: white; border-color: #E12229; }
    .btn-primary { background: #0f172a; color: white; width: 100%; padding: 12px; font-size: 14px; }
    .btn-primary:hover { background: #1e293b; }
    .status-badge { display: inline-block; padding: 6px 14px; border-radius: 20px; font-size: 12px; font-weight: 700; margin-top: 10px; }
    .status-pending { background: #fef3c7; color: #b45309; }
    .status-paid { background: #dcfce7; color: #15803d; }
    .payload-box { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px; font-size: 10px; color: #64748b; word-break: break-all; margin-top: 14px; text-align: left; max-height: 70px; overflow-y: auto; }
  </style>
</head>
<body>

<div class="khqr-card">
  <div class="header">
    <h2>KHQR</h2>
    <p>National Bank of Cambodia</p>
  </div>

  <div class="content">
    <div class="merchant-name">${config.bakongMerchantName}</div>
    <div class="account-id">${config.bakongAccountId}</div>

    <div class="controls" style="margin-top: 14px;">
      <button class="btn btn-outline active" onclick="setCurrency('KHR', 1000)">1,000 ៛</button>
      <button class="btn btn-outline" onclick="setCurrency('KHR', 10000)">10,000 ៛</button>
      <button class="btn btn-outline" onclick="setCurrency('USD', 1.00)">\$1.00 USD</button>
    </div>

    <div class="amount-display" id="amountDisplay">1,000 KHR</div>

    <div class="qr-container">
      <img id="qrImage" src="" alt="KHQR Code">
    </div>

    <div>
      <span id="statusBadge" class="status-badge status-pending">● Awaiting Payment</span>
    </div>

    <div style="margin-top: 16px;">
      <button class="btn btn-primary" onclick="checkStatus()">Check Payment Status</button>
    </div>

    <div class="payload-box">
      <strong>MD5:</strong> <span id="md5Display">-</span><br>
      <strong>Payload:</strong> <span id="payloadDisplay">-</span>
    </div>
  </div>
</div>

<script>
  let currentCurrency = 'KHR';
  let currentAmount = 1000;
  let currentMd5 = '';

  async function generateQr() {
    try {
      const res = await fetch('/api/v1/payments/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          amount: currentAmount,
          currency: currentCurrency,
          billNumber: 'INV-' + Date.now().toString().slice(-6)
        })
      });
      const data = await res.json();
      if (data.success) {
        currentMd5 = data.data.md5;
        document.getElementById('md5Display').innerText = data.data.md5;
        document.getElementById('payloadDisplay').innerText = data.data.qr;
        
        const qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&margin=10&data=' + encodeURIComponent(data.data.qr);
        document.getElementById('qrImage').src = qrUrl;

        document.getElementById('statusBadge').className = 'status-badge status-pending';
        document.getElementById('statusBadge').innerText = '● Awaiting Payment';
      }
    } catch (e) {
      console.error('Error generating QR:', e);
    }
  }

  function setCurrency(cur, amt) {
    currentCurrency = cur;
    currentAmount = amt;
    document.getElementById('amountDisplay').innerText = cur === 'KHR' 
      ? amt.toLocaleString() + ' KHR' 
      : '\$' + amt.toFixed(2) + ' USD';

    document.querySelectorAll('.controls .btn-outline').forEach(btn => {
      btn.classList.remove('active');
      if (btn.innerText.includes(cur === 'KHR' ? amt.toLocaleString() : amt.toFixed(2))) {
        btn.classList.add('active');
      }
    });

    generateQr();
  }

  async function checkStatus() {
    if (!currentMd5) return;
    const badge = document.getElementById('statusBadge');
    badge.innerText = 'Checking Bakong...';

    try {
      const res = await fetch('/api/v1/payments/verify?md5=' + encodeURIComponent(currentMd5));
      const result = await res.json();

      if (result.isPaid) {
        badge.className = 'status-badge status-paid';
        badge.innerText = '✔ PAID & VERIFIED';
      } else {
        badge.className = 'status-badge status-pending';
        badge.innerText = '● ' + (result.message || 'Payment Pending');
      }
    } catch (e) {
      badge.innerText = 'Error checking status';
    }
  }

  generateQr();
</script>

</body>
</html>
''';

  return Response(
    body: html,
    headers: {
      HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
    },
  );
}

