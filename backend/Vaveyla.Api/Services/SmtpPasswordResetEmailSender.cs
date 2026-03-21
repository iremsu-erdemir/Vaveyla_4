using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Options;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Services;

public sealed class SmtpPasswordResetEmailSender : IPasswordResetEmailSender
{
    private readonly EmailSettings _emailSettings;
    private readonly ILogger<SmtpPasswordResetEmailSender> _logger;

    public SmtpPasswordResetEmailSender(
        IOptions<EmailSettings> emailSettings,
        ILogger<SmtpPasswordResetEmailSender> logger)
    {
        _emailSettings = emailSettings.Value;
        _logger = logger;
    }

    public async Task SendResetCodeAsync(string toEmail, string resetCode, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_emailSettings.SmtpHost) ||
            string.IsNullOrWhiteSpace(_emailSettings.FromAddress))
        {
            throw new InvalidOperationException("Email settings are missing. Configure Email:SmtpHost and Email:FromAddress.");
        }

        using var message = new MailMessage
        {
            From = new MailAddress(_emailSettings.FromAddress, _emailSettings.FromName),
            Subject = "Vaveyla - Sifre Sifirlama Dogrulama Kodu",
            Body = BuildBody(resetCode),
            IsBodyHtml = false
        };
        message.To.Add(new MailAddress(toEmail));

        using var smtpClient = new SmtpClient(_emailSettings.SmtpHost, _emailSettings.SmtpPort)
        {
            EnableSsl = _emailSettings.EnableSsl,
            DeliveryMethod = SmtpDeliveryMethod.Network,
            UseDefaultCredentials = string.IsNullOrWhiteSpace(_emailSettings.Username)
        };

        if (!smtpClient.UseDefaultCredentials)
        {
            smtpClient.Credentials = new NetworkCredential(
                _emailSettings.Username,
                _emailSettings.Password);
        }

        await smtpClient.SendMailAsync(message, cancellationToken);
        _logger.LogInformation("Password reset code e-mail sent to {Email}.", toEmail);
    }

    private static string BuildBody(string resetCode)
    {
        return
            "Sifre sifirlama talebiniz alindi.\n\n" +
            $"Dogrulama kodunuz: {resetCode}\n\n" +
            "Bu kod 10 dakika boyunca gecerlidir.\n" +
            "Eger bu islemi siz yapmadiysaniz bu e-postayi dikkate almayabilirsiniz.";
    }
}
