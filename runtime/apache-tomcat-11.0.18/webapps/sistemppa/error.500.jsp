<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>500 â€“ Ralat Pelayan | SPPPA</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700;800&display=swap');
        :root { --brand-blue: #0d5c8f; --brand-navy: #08334d; --brand-gold: #e7bf56; }
        * { box-sizing: border-box; }
        body { margin: 0; min-height: 100vh; display: grid; place-items: center;
               background: linear-gradient(135deg, #08334d 0%, #0d5c8f 60%, #eef7ff 150%);
               font-family: 'Source Sans 3', 'Trebuchet MS', sans-serif; }
        .card { background: white; border-radius: 20px; padding: 48px 52px; text-align: center;
                max-width: 520px; width: 90%; box-shadow: 0 24px 60px rgba(8,51,77,0.25); }
        .code { font-size: 96px; font-weight: 800; color: #c0392b; line-height: 1;
                margin-bottom: 8px; letter-spacing: -4px; }
        .title { font-size: 24px; font-weight: 700; color: var(--brand-navy); margin: 0 0 10px; }
        .desc { color: #5d7484; font-size: 15px; margin: 0 0 28px; line-height: 1.6; }
        .btn { display: inline-block; padding: 12px 26px; border-radius: 12px; font-weight: 700;
               font-size: 15px; text-decoration: none; margin: 6px; transition: transform .15s; }
        .btn:hover { transform: translateY(-2px); }
        .btn-primary { background: linear-gradient(180deg, #0f6fa8 0%, #0d5c8f 100%); color: white; }
        .btn-secondary { background: #e2edf5; color: var(--brand-navy); }
        .divider { border: none; border-top: 1px solid #d4e1ec; margin: 24px 0; }
        .hint { font-size: 13px; color: #94a3b8; }
    </style>
</head>
<body>
<div class="card">
    <div class="code">500</div>
    <h1 class="title">Ralat Dalaman Pelayan</h1>
    <p class="desc">Maaf, berlaku ralat semasa memproses permintaan anda. Pasukan teknikal telah dimaklumkan. Sila cuba lagi sebentar.</p>
    <a href="${pageContext.request.contextPath}/login" class="btn btn-primary">Halaman Utama</a>
    <a href="javascript:history.back()" class="btn btn-secondary">Kembali</a>
    <hr class="divider">
    <p class="hint">Sistem Pendaftaran Pembekal dan Produk Air (SPPPA) &mdash; Jabatan Air Sabah</p>
</div>
</body>
</html>

