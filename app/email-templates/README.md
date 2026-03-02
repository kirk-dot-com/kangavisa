# KangaVisa — Email Templates

Supabase transactional email templates with KangaVisa branding.

---

## Files

| File | Supabase template | When sent |
|---|---|---|
| `signup-confirm.html` | **Confirm signup** | After `supabase.auth.signUp()` — user must click link to activate |
| `reset-password.html` | **Reset password** | After `supabase.auth.resetPasswordForEmail()` |
| `email-change.html` | **Change email address** | After `supabase.auth.updateUser({ email: '...' })` |

---

## How to deploy to Supabase

1. Open the [Supabase dashboard](https://supabase.com/dashboard) and select the **KangaVisa** project.
2. In the left sidebar go to **Authentication → Email Templates**.
3. For each template in the table above:
   a. Select the template name from the dropdown (e.g. "Confirm signup").
   b. Set **Subject line** (see below).
   c. Replace the **Message body** with the full contents of the corresponding HTML file.
   d. Click **Save**.
4. To test, trigger each flow:
   - **Signup**: create a new account at `/auth/signup` with a test email inbox.
   - **Reset**: submit `/auth/reset-request` with the test email.
   - **Email change**: update email in account settings once that page is built.

---

## Subject lines

| Template | Subject |
|---|---|
| Confirm signup | `Confirm your KangaVisa email address` |
| Reset password | `Reset your KangaVisa password` |
| Email change | `Confirm your new KangaVisa email address` |

---

## Variables

Supabase injects these variables into the template at send time:

| Variable | Replaced with |
|---|---|
| `{{ .ConfirmationURL }}` | The one-time action URL (confirm / reset / change) |
| `{{ .Email }}` | The recipient's email address (not currently used in templates) |

> **Do not change** `{{ .ConfirmationURL }}` — it must remain exactly as-is for Supabase to inject the correct link.

---

## Design tokens used

| Token | Value | Use |
|---|---|---|
| Navy | `#0B1F3B` | Header background, body text |
| Gold | `#c9902a` | Logo mark background, CTA button, callout border |
| Teal | `#1a7a72` | Inline link colour in body |
| Slate grey | `#f1f5f9` | Page background |
| White | `#ffffff` | Card body background |

No web fonts used — email clients block them. All type renders in `Arial, Helvetica, sans-serif`.

---

## Updating templates

Edit the HTML file in this directory, preview it in a browser (`open signup-confirm.html`), then re-paste into the Supabase dashboard. There is no automated sync; the dashboard is the source of truth for what Supabase sends.
