// Landing page — KangaVisa hero + value pillars
// US-A1 | Brand Guidelines §13

import Link from "next/link";
import styles from "./page.module.css";

const VALUE_PILLARS = [
  {
    icon: "🧭",
    title: "Know your pathway",
    body: "Understand which visa fits your situation, the key criteria, and the documents that matter — before you start.",
  },
  {
    icon: "📋",
    title: "Build your evidence",
    body: "A structured, visa-specific checklist maps each document to what it actually proves, so nothing is forgotten.",
  },
  {
    icon: "🔍",
    title: "Fix the gaps",
    body: "KangaVisa surfaces risk flags — inconsistencies, missing evidence, timing issues — with plain-English explanations and fix paths.",
  },
  {
    icon: "📦",
    title: "Export with confidence",
    body: "Generate a structured readiness pack you can share with your migration agent or keep as a personal record.",
  },
] as const;

export default function HomePage() {
  return (
    <>
      {/* Hero */}
      <section className={styles.hero}>
        <div className={`container ${styles.hero__inner}`}>
          <div className={styles.hero__badge}>
            <span className="badge badge--teal">Readiness, not advice</span>
          </div>
          <h1 className={`h1 ${styles.hero__heading}`}>
            Prepare a decision-ready
            <br />
            <span className={styles.hero__accent}>Australian visa application pack</span>
          </h1>
          <p className={`body-lg ${styles.hero__sub}`}>
            KangaVisa helps people preparing Australian visa applications turn complex
            immigration requirements into a clear, structured evidence plan — without
            predicting outcomes.
          </p>
          <div className={styles.hero__ctas}>
            <Link href="/pathway" className="btn btn--primary btn--lg">
              Start your readiness check →
            </Link>
            <Link href="/auth/signup" className="btn btn--secondary btn--lg">
              Create account
            </Link>
          </div>
          <p className={`caption ${styles.hero__disclaimer}`}>
            Not legal advice · No approval guarantees · Privacy-first
          </p>
        </div>
      </section>

      {/* Value pillars */}
      <section className={`section ${styles.pillars}`}>
        <div className="container">
          <h2 className={`h2 ${styles.pillars__heading}`}>
            Clarity you can act on
          </h2>
          <p className={`body-lg ${styles.pillars__sub}`}>
            Four steps from confusion to a structured readiness plan.
          </p>
          <div className={styles.pillars__grid}>
            {VALUE_PILLARS.map((pillar, i) => (
              <div key={i} className={`card ${styles.pillar}`}>
                <span className={styles.pillar__icon} aria-hidden="true">
                  {pillar.icon}
                </span>
                <h3 className={`h3 ${styles.pillar__title}`}>{pillar.title}</h3>
                <p className={`body-sm ${styles.pillar__body}`}>{pillar.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA band */}
      <section className={styles.cta_band}>
        <div className={`container ${styles.cta_band__inner}`}>
          <div>
            <h2 className={`h2 ${styles.cta_band__heading}`}>
              Ready to build your readiness pack?
            </h2>
            <p className="body-sm" style={{ color: "#94A3B8", marginTop: "var(--sp-2)" }}>
              Choose your visa type and we will generate a tailored evidence checklist
              grounded in current Australian migration law.
            </p>
          </div>
          <Link href="/pathway" className="btn btn--primary btn--lg">
            Choose your visa →
          </Link>
        </div>
      </section>
    </>
  );
}
