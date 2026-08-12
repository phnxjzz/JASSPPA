package com.sistemppa.util;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas EmailUtil.
 * Dipanggil sebagai util/helper oleh servlet atau service.
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.util.Properties;
import java.util.logging.Logger;

public class EmailUtil {
    private static final Logger LOGGER = Logger.getLogger(EmailUtil.class.getName());

    private final String host;
    private final int port;
    private final String username;
    private final String password;
    private final String fromAddress;
    private final boolean auth;
    private final boolean tls;

    public EmailUtil(String host, int port, String username, String password,
            String fromAddress, boolean auth, boolean tls) {
        this.host = host;
        this.port = port;
        this.username = username;
        this.password = password;
        this.fromAddress = fromAddress;
        this.auth = auth;
        this.tls = tls;
    }

    public boolean sendHtml(String to, String subject, String htmlBody) {
        Properties props = new Properties();
        props.put("mail.smtp.host", host);
        props.put("mail.smtp.port", String.valueOf(port));
        props.put("mail.smtp.auth", String.valueOf(auth));
        if (tls) {
            props.put("mail.smtp.starttls.enable", "true");
        }

        Authenticator authenticator = auth ? new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(username, password);
            }
        } : null;

        try {
            Session session = Session.getInstance(props, authenticator);
            Message msg = new MimeMessage(session);
            msg.setFrom(new InternetAddress(fromAddress));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            msg.setSubject(subject);
            msg.setContent(htmlBody, "text/html; charset=utf-8");
            Transport.send(msg);
            LOGGER.info("Email sent to: " + to);
            return true;
        } catch (MessagingException e) {
            LOGGER.warning("Failed to send email to " + to + ": " + e.getMessage());
            return false;
        }
    }
}

