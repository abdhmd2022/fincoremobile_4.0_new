/// Shared branded HTML shell for every email this app sends directly
/// (support requests from AssistantChat.dart, new-user credentials from
/// CreateUser.dart) - kept identical to the layout tally-admin-api's own
/// mail-templates.ts now uses for every email *it* sends (login/reset/
/// verify OTPs, password-changed notice), so nothing looks like it came
/// from a different product depending on which flow triggered it. Only
/// [bodyHtml] - the content between the logo and the footer - differs per
/// email.
String buildBrandedEmailHtml(String bodyHtml) {
  return '''
<!DOCTYPE html>
<html>
  <body style="font-family: Arial, sans-serif; background: #f4f4f5; padding: 24px;">
    <div style="max-width: 480px; margin: 0 auto; border: 1px solid #ccc; border-radius: 8px; padding: 30px; text-align: center; background: #ffffff;">
      <a href="https://tallyuae.ae/">
        <img src="https://mobile.chaturvedigroup.com/fincore_logo/tally_1.png" alt="Fincore Go" style="width: 150px; height: auto; margin-bottom: 10px;">
      </a>
      $bodyHtml
      <br>
      <div style="text-align: start;">
        <p style="color: #999999; font-style: italic; font-size: 12px">This is a system generated email. Do not reply.</p>
      </div>
      <div style="text-align: start; border-top: 1px solid #ccc; padding-top: 10px;">
        <p style="font-size: 10px; font-family: Arial, sans-serif; color: #a3a2a2;">© 2023-2026 Chaturvedi Software House LLC. All Rights Reserved</p>
        <p style="font-size: 10px; font-family: Arial, sans-serif; color: #a3a2a2; padding-top: 0px">513 Al Khaleej Center Bur Dubai, Dubai United Arab Emirates, +97143258361</p>
      </div>
    </div>
  </body>
</html>''';
}
