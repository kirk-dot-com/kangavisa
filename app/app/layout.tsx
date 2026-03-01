// US-A1 | Brand Guidelines §4–7
import type { Metadata } from "next";
import "./globals.css";
import AppHeader from "./components/AppHeader";

export const metadata: Metadata = {
  title: "KangaVisa — Visa Readiness",
  description:
    "KangaVisa helps you prepare a decision-ready visa application pack — clear, structured, and explainable. Not legal advice.",
  keywords: ["visa", "australia", "immigration", "readiness", "student visa", "partner visa"],
  icons: {
    icon: [
      { url: "/icon.png", sizes: "512x512", type: "image/png" },
      { url: "/icon-48.png", sizes: "48x48", type: "image/png" },
      { url: "/icon-32.png", sizes: "32x32", type: "image/png" },
    ],
    apple: [{ url: "/apple-icon.png", sizes: "512x512", type: "image/png" }],
    shortcut: "/icon-32.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        <AppHeader />
        <main id="main-content">{children}</main>
        <footer
          style={{
            background: "var(--color-navy)",
            color: "#94A3B8",
            textAlign: "center",
            padding: "var(--sp-6)",
            fontSize: "var(--text-xs)",
            marginTop: "var(--sp-16)",
          }}
        >
          <p>
            KangaVisa is an information and preparation tool. It is not legal advice
            and does not guarantee outcomes.{" "}
            <a
              href="https://www.mara.gov.au"
              target="_blank"
              rel="noopener noreferrer"
              style={{ color: "var(--color-gold)", textDecoration: "underline" }}
            >
              Find a registered migration agent
            </a>
            .
          </p>
          <p style={{ marginTop: "var(--sp-2)" }}>
            © {new Date().getFullYear()} KangaVisa
          </p>
        </footer>
      </body>
    </html>
  );
}
