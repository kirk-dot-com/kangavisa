// PWA Web App Manifest — Next.js 14 route handler
// US-A2 | Brand Guidelines §4 (navy #0B1F3B, gold #c9902a)
// Enables "Add to Home Screen" on mobile browsers

import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
    return {
        name: "KangaVisa — Visa Readiness",
        short_name: "KangaVisa",
        description:
            "Prepare a decision-ready Australian visa application pack. Clear, structured, and explainable.",
        start_url: "/",
        display: "standalone",
        background_color: "#0B1F3B",
        theme_color: "#0B1F3B",
        orientation: "portrait-primary",
        categories: ["productivity", "utilities"],
        icons: [
            {
                src: "/icon-192.png",
                sizes: "192x192",
                type: "image/png",
                purpose: "any",
            },
            {
                src: "/icon-192.png",
                sizes: "192x192",
                type: "image/png",
                purpose: "maskable",
            },
            {
                src: "/icon.png",
                sizes: "512x512",
                type: "image/png",
                purpose: "any",
            },
            {
                src: "/apple-icon.png",
                sizes: "512x512",
                type: "image/png",
                purpose: "any",
            },
        ],
    };
}
