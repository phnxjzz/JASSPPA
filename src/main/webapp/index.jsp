<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sistem Pendaftaran Produk Air (SPPA)</title>
    <style>
        :root {
            --brand-blue: #0097d9;
            --brand-navy: #06344f;
            --brand-yellow: #fff212;
            --text: #173040;
            --muted: #64808f;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: var(--text); background: #f8fbfd; }
        .navbar { background: linear-gradient(130deg, var(--brand-navy) 0%, var(--brand-blue) 74%, var(--brand-yellow) 190%); color: white; padding: 16px 30px; display: flex; justify-content: space-between; align-items: center; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand img { width: 52px; background: white; border-radius: 16px; padding: 6px; }
        .brand-text strong { display: block; font-size: 18px; }
        .brand-text span { font-size: 12px; opacity: 0.88; }
        .navbar a { color: white; text-decoration: none; margin-left: 20px; font-weight: 600; }
        .hero { position: relative; overflow: hidden; background: linear-gradient(135deg, #06344f 0%, #0097d9 62%, #fff4a5 180%); color: white; padding: 72px 30px; }
        .hero::after { content: ""; position: absolute; right: -40px; top: -30px; width: 220px; height: 220px; border-radius: 50%; background: rgba(255, 242, 18, 0.24); }
        .hero-inner { max-width: 1200px; margin: 0 auto; display: grid; grid-template-columns: 1.5fr 1fr; gap: 24px; align-items: center; }
        .hero h1 { font-size: 44px; margin-bottom: 14px; max-width: 760px; }
        .hero p { font-size: 18px; margin-bottom: 26px; max-width: 700px; }
        .hero-btn { display: inline-block; padding: 12px 28px; background: white; color: var(--brand-navy); text-decoration: none; border-radius: 999px; font-weight: 700; margin: 10px 10px 0 0; }
        .hero-side { background: rgba(255, 255, 255, 0.14); backdrop-filter: blur(8px); border: 1px solid rgba(255,255,255,0.24); border-radius: 22px; padding: 18px; }
        .hero-side img { width: 100%; border-radius: 16px; }
        .container { max-width: 1200px; margin: 0 auto; padding: 44px 20px; }
        .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; margin-bottom: 50px; }
        .feature { padding: 24px; border-radius: 18px; background: white; border: 1px solid #d9e8f1; box-shadow: 0 12px 30px rgba(6, 52, 79, 0.06); }
        .feature h3 { color: var(--brand-navy); margin-bottom: 10px; }
        .feature p { color: var(--muted); font-size: 14px; }
        .roles { background: linear-gradient(180deg, #eff8ff 0%, #f8fbfd 100%); padding: 46px 0; margin: 10px 0 0; }
        .role-container { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px; margin: 30px auto 0; max-width: 1200px; padding: 0 20px; }
        .role-card { background: white; padding: 30px; border-radius: 20px; box-shadow: 0 12px 30px rgba(6, 52, 79, 0.06); border: 1px solid #d9e8f1; }
        .role-card h3 { color: var(--brand-navy); margin-bottom: 15px; font-size: 20px; }
        .role-card ul { list-style: none; margin-bottom: 20px; }
        .role-card li { padding: 10px 0; border-bottom: 1px solid #edf3f6; color: var(--muted); font-size: 14px; }
        .role-card li:before { content: "✓ "; color: #0f7a3d; font-weight: bold; margin-right: 8px; }
        .role-card li:last-child { border-bottom: none; }
        footer { background: #072d43; color: white; text-align: center; padding: 30px; }
        @media (max-width: 960px) { .hero-inner { grid-template-columns: 1fr; } .navbar { flex-direction: column; align-items: flex-start; gap: 12px; } .navbar a { margin-left: 0; margin-right: 16px; } }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png" alt="Logo Jabatan Air Sabah">
            <div class="brand-text">
                <strong>SPPA</strong>
                <span>Jabatan Air Negeri Sabah</span>
            </div>
        </div>
        <div>
            <a href="${pageContext.request.contextPath}/login">Log Masuk</a>
            <a href="${pageContext.request.contextPath}/register">Daftar Pemohon</a>
        </div>
    </div>

    <div class="hero">
        <div class="hero-inner">
            <div>
                <h1>Sistem rasmi pendaftaran produk air dengan aliran digital penuh</h1>
                <p>Portal ini menyatukan borang pemohon, semakan pentadbir, senarai produk berdaftar dari MySQL, serta rujukan hubungan rasmi Jabatan Air Negeri Sabah.</p>
                <a href="${pageContext.request.contextPath}/login" class="hero-btn">Log Masuk</a>
                <a href="${pageContext.request.contextPath}/register" class="hero-btn">Buka Akaun Pemohon</a>
            </div>
            <div class="hero-side">
                <img src="${pageContext.request.contextPath}/assets/images/contact-jans.png" alt="Maklumat hubungan Jabatan Air Sabah">
            </div>
        </div>
    </div>

    <div class="container">
        <h2 style="margin-bottom: 26px; text-align: center;">Ciri-ciri Utama Sistem</h2>
        <div class="features">
            <div class="feature">
                <h3>Pengurusan Permohonan Online</h3>
                <p>Pemohon mengisi PPP1 secara digital dan memuat naik lampiran PPP2 terus ke sistem tanpa borang manual.</p>
            </div>
            <div class="feature">
                <h3>Semakan Pentadbir Berstruktur</h3>
                <p>Pentadbir menapis permohonan mengikut status, mencari pemohon, dan mengekstrak laporan PDF atau Excel.</p>
            </div>
            <div class="feature">
                <h3>Senarai Produk Berdaftar</h3>
                <p>Rekod produk rasmi dipaparkan terus dari MySQL supaya pemohon dan pentadbir melihat sumber data yang sama.</p>
            </div>
        </div>
    </div>

    <div class="roles">
        <div style="max-width: 1200px; margin: 0 auto; padding: 0 20px;">
            <h2 style="text-align: center; margin-bottom: 10px;">Peranan Pengguna</h2>
            <p style="text-align:center;color:#64808f;">Aliran kerja dipisahkan jelas antara pemohon dan pentadbir tanpa memecahkan sumber data.</p>
        </div>
        <div class="role-container">
            <div class="role-card">
                <h3>Pentadbir</h3>
                <ul>
                    <li>Melihat dan menyemak permohonan</li>
                    <li>Meluluskan, menolak atau menggantung permohonan</li>
                    <li>Mencari rekod dan menapis mengikut status</li>
                    <li>Menjana laporan PDF dan Excel</li>
                    <li>Menyemak senarai produk berdaftar</li>
                </ul>
            </div>
            <div class="role-card">
                <h3>Pemohon / Pengguna</h3>
                <ul>
                    <li>Membuat permohonan pendaftaran baharu</li>
                    <li>Mengemas kini profil sebenar dan email</li>
                    <li>Menukar kata laluan dari halaman profil</li>
                    <li>Melihat senarai produk berdaftar</li>
                    <li>Mengesan status permohonan sendiri</li>
                </ul>
            </div>
        </div>
    </div>

    <footer>
        <p>&copy; 2026 Sistem Pendaftaran Produk Air (SPPA). Semua hak terpelihara.</p>
        <p>Jabatan Air Negeri Sabah</p>
    </footer>
</body>
</html>
