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
        .brand-logos { display: flex; align-items: center; gap: 10px; }
        .brand-logo { width: 52px; height: 52px; border-radius: 16px; object-fit: contain; padding: 4px; }
        .brand-text strong { display: block; font-size: 18px; }
        .brand-text span { font-size: 12px; opacity: 0.88; }
        .navbar a { color: white; text-decoration: none; margin-left: 20px; font-weight: 600; }
        .hero { position: relative; overflow: hidden; background: linear-gradient(135deg, #06344f 0%, #0097d9 62%, #fff4a5 180%); color: white; padding: 72px 30px; }
        .hero::after { content: ""; position: absolute; right: -40px; top: -30px; width: 220px; height: 220px; border-radius: 50%; background: rgba(255, 242, 18, 0.24); }
        .hero-watermark { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: contain; object-position: center; opacity: 0.08; pointer-events: none; z-index: 0; padding: 40px; }
        .hero-inner { max-width: 1200px; margin: 0 auto; display: grid; grid-template-columns: 1.5fr 1fr; gap: 24px; align-items: center; }
        .hero h1 { font-size: 44px; margin-bottom: 14px; max-width: 760px; }
        .hero p { font-size: 18px; margin-bottom: 26px; max-width: 700px; }
        .hero-btn { display: inline-block; padding: 12px 28px; color: #fff; text-decoration: none; border-radius: 999px; font-weight: 700; margin: 10px 10px 0 0; border: 2px solid #fff; background: rgba(255, 255, 255, 0.08); box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.5); }
        .hero-btn:hover, .hero-btn:focus { background: rgba(255, 255, 255, 0.16); border-color: #fff; color: #fff; }
        .hero-side { background: rgba(255, 255, 255, 0.14); backdrop-filter: blur(8px); border: 1px solid rgba(255,255,255,0.24); border-radius: 22px; padding: 18px; }
        .hero-contact { width: 100%; border-radius: 16px; border: 1px solid rgba(255,255,255,0.28); background: rgba(6, 52, 79, 0.35); padding: 16px; }
        .hero-contact h3 { margin: 0 0 10px; font-size: 16px; }
        .hero-contact p { margin: 6px 0; font-size: 14px; }
        .container { max-width: 1200px; margin: 0 auto; padding: 44px 20px; }
        footer { background: #072d43; color: white; text-align: center; padding: 30px; }
        @media (max-width: 960px) { .hero-inner { grid-template-columns: 1fr; } .navbar { flex-direction: column; align-items: flex-start; gap: 12px; } .navbar a { margin-left: 0; margin-right: 16px; } }
                    /* Enforce visible white border on all clickable buttons */
        button,
        input[type="submit"],
        input[type="button"],
        .btn,
        .login-btn,
        .modal-close,
        .btn-attachment,
        .attachment-list button,
        a.btn {
            border: 1px solid #fff !important;
            box-shadow: inset 0 0 0 1px #fff, 0 1px 2px rgba(0, 0, 0, 0.18) !important;
        }

        button:hover,
        input[type="submit"]:hover,
        input[type="button"]:hover,
        .btn:hover,
        .login-btn:hover,
        .modal-close:hover,
        .btn-attachment:hover,
        .attachment-list button:hover,
        a.btn:hover,
        button:focus,
        input[type="submit"]:focus,
        input[type="button"]:focus,
        .btn:focus,
        .login-btn:focus,
        .modal-close:focus,
        .btn-attachment:focus,
        .attachment-list button:focus,
        a.btn:focus {
            border: 1px solid #fff !important;
            box-shadow: inset 0 0 0 1px #fff, 0 0 0 2px rgba(255, 255, 255, 0.35), 0 1px 2px rgba(0, 0, 0, 0.18) !important;
        }</style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <div class="brand-logos">
                <img src="${pageContext.request.contextPath}/assets/images/logo-sabah-2025.png?v=3" class="brand-logo" alt="Logo Sabah">
                <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            </div>
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
        <img src="${pageContext.request.contextPath}/assets/images/jabatan-air-sabah-bg.png" class="hero-watermark" alt="" aria-hidden="true">
        <div class="hero-inner" style="position:relative;z-index:1;">
            <div>
                <h1>Selamat datang ke Sistem Pendaftaran Produk Air</h1>
                <a href="${pageContext.request.contextPath}/login" class="hero-btn">Log Masuk</a>
                <a href="${pageContext.request.contextPath}/register" class="hero-btn">Buka Akaun Pemohon</a>
            </div>
            <div class="hero-side">
                <div class="hero-contact" aria-label="Maklumat hubungan Jabatan Air Sabah">
                    <h3>Hubungi JANS</h3>
                    <p>Telefon: 088-326888</p>
                    <p>Email: info@jwater.gov.my</p>
                    <p>Alamat: Kota Kinabalu, Sabah</p>
                </div>
            </div>
        </div>
    </div>

    <footer>
        <p>&copy; 2026 Sistem Pendaftaran Produk Air (SPPA). Semua hak terpelihara.</p>
        <p>Jabatan Air Negeri Sabah</p>
    </footer>
</body>
</html>







