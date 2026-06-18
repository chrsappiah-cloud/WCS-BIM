#!/usr/bin/env python3
"""Generate 15-page investor brochure PDF with app icon and promotional images."""

from __future__ import annotations

from datetime import date
from pathlib import Path

from fpdf import FPDF

ROOT = Path(__file__).resolve().parents[1]
MARKETING = ROOT / "Marketing"
DESKTOP = Path.home() / "Desktop" / "WCS-BIM-Production"
OUT = DESKTOP / "WCS-BIM-Investor-Brochure-15pg.pdf"
ICON = MARKETING / "AppIcon-1024.png"
PROMOS = [
    ("promo-01-projects.png", "Projects & Site Intelligence", "Unified project hub with pearl hero cards, parametric chips, and one-tap workspace entry for field teams."),
    ("promo-02-ar-site.png", "AR Field Capture", "Viewfinder-grade AR site capture tied to live project context for anchors, landmarks, and on-site verification."),
    ("promo-03-ai-assistant.png", "AI Design Assistant", "Massing, zoning, and circulation prompts with offline-safe fallbacks and persisted AIInteraction history per project."),
    ("promo-04-export.png", "Export Center", "IFC, COBie CSV, PDF sheets, and Revit/DWG handoff from a single professional export console."),
    ("promo-05-settings.png", "Design Programs & Cloud", "One-tap design pack install, CloudKit sync, and enterprise-ready settings for distributed teams."),
]


def _txt(s: str) -> str:
    replacements = {
        "\u2014": "-",
        "\u2013": "-",
        "\u2192": "->",
        "\u00b7": "-",
        "\u2019": "'",
        "\u201c": '"',
        "\u201d": '"',
    }
    for old, new in replacements.items():
        s = s.replace(old, new)
    return s.encode("ascii", "replace").decode("ascii")


class BrochurePDF(FPDF):
    def header(self) -> None:
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(90, 90, 100)
        self.cell(0, 6, _txt("ArchFusion BIM | Confidential Investor Brief"), align="C")
        self.ln(2)

    def footer(self) -> None:
        if self.page_no() == 1:
            return
        self.set_y(-12)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(120, 120, 130)
        self.cell(0, 8, f"Page {self.page_no()} of 15", align="C")

    def heading(self, title: str, subtitle: str = "") -> None:
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "B", 20)
        self.set_text_color(43, 47, 138)
        self.multi_cell(self.epw, 9, _txt(title))
        if subtitle:
            self.ln(2)
            self.set_x(self.l_margin)
            self.set_font("Helvetica", "", 11)
            self.set_text_color(80, 80, 90)
            self.multi_cell(self.epw, 5, _txt(subtitle))
        self.ln(4)

    def body(self, text: str) -> None:
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "", 10.5)
        self.set_text_color(35, 35, 40)
        self.multi_cell(self.epw, 5.5, _txt(text))
        self.ln(3)

    def bullet_list(self, items: list[str]) -> None:
        self.set_font("Helvetica", "", 10)
        for item in items:
            self.set_x(self.l_margin)
            self.multi_cell(self.epw, 5, _txt(f"- {item}"))
        self.ln(2)


def page_cover(pdf: BrochurePDF) -> None:
    pdf.add_page()
    pdf.set_fill_color(246, 247, 250)
    pdf.rect(0, 0, 210, 297, style="F")
    if ICON.exists():
        pdf.image(str(ICON), x=75, y=35, w=60)
    pdf.set_xy(10, 110)
    pdf.set_font("Helvetica", "B", 28)
    pdf.set_text_color(43, 47, 138)
    pdf.cell(190, 14, _txt("ArchFusion BIM"), align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("Helvetica", "", 14)
    pdf.set_text_color(15, 169, 134)
    pdf.cell(190, 8, _txt("Field-Ready BIM for iOS"), align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(4)
    pdf.set_font("Helvetica", "", 12)
    pdf.set_text_color(60, 60, 70)
    pdf.cell(190, 7, _txt("Investor Promotional Brochure"), align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(190, 7, _txt("WCS Design System | 15 Pages"), align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.set_xy(10, 265)
    pdf.set_font("Helvetica", "I", 10)
    pdf.set_text_color(100, 100, 110)
    pdf.cell(190, 6, _txt(f"Confidential | {date.today():%B %Y}"), align="C")


def page_text(pdf: BrochurePDF, title: str, subtitle: str, paragraphs: list[str], bullets: list[str] | None = None) -> None:
    pdf.add_page()
    pdf.heading(title, subtitle)
    for p in paragraphs:
        pdf.body(p)
    if bullets:
        pdf.bullet_list(bullets)


def page_feature(pdf: BrochurePDF, image_name: str, title: str, caption: str) -> None:
    path = MARKETING / "AppStore" / image_name
    pdf.add_page()
    pdf.heading(title, "Product capability")
    if path.exists():
        pdf.image(str(path), x=10, y=42, w=190)
        pdf.set_y(175)
    pdf.body(caption)
    pdf.body(
        "Built with SwiftUI, SwiftData, and optional CloudKit sync. "
        "Tiered XCTest coverage and TestFlight admin tooling de-risk enterprise rollout."
    )


def page_closing(pdf: BrochurePDF) -> None:
    pdf.add_page()
    pdf.set_fill_color(43, 47, 138)
    pdf.rect(0, 0, 210, 55, style="F")
    pdf.set_y(18)
    pdf.set_font("Helvetica", "B", 22)
    pdf.set_text_color(255, 255, 255)
    pdf.cell(190, 10, _txt("Partner With WCS"), align="C", new_x="LMARGIN", new_y="NEXT")
    if ICON.exists():
        pdf.image(str(ICON), x=85, y=70, w=40)
    pdf.set_y(120)
    pdf.set_text_color(35, 35, 40)
    pdf.heading("Next Steps", "")
    pdf.bullet_list([
        "Schedule a live TestFlight demo on iPhone 17 Pro Max hardware.",
        "Review subscription tiers: Pro, Team, Enterprise (StoreKit 2).",
        "Align on pilot customers in commercial and airport verticals.",
        "Discuss seed / Series A allocation and GTM co-investment.",
    ])
    pdf.ln(4)
    pdf.body("Contact: investors@wcs.example.com | wcs.WCS-BIM on App Store Connect")
    pdf.body("GitHub: github.com/chrsappiah-cloud/WCS-BIM")


def build() -> None:
    DESKTOP.mkdir(parents=True, exist_ok=True)
    pdf = BrochurePDF()
    pdf.set_margins(15, 18, 15)
    pdf.set_auto_page_break(auto=True, margin=20)

    page_cover(pdf)

    page_text(
        pdf,
        "Executive Summary",
        "Professional BIM in the pocket of every engineer",
        [
            "ArchFusion BIM (WCS-BIM) is an iOS-native workspace that unifies projects, "
            "site capture, AR visualization, AI-assisted design, and IFC/COBie export for "
            "construction and infrastructure teams.",
            "The product targets the gap between heavyweight desktop BIM and fragmented "
            "field apps by delivering a tokens-first professional UI, offline SwiftData "
            "persistence, and enterprise CloudKit handoff.",
            "We are raising capital to accelerate App Store launch, vertical design packs, "
            "and enterprise seat expansion.",
        ],
        [
            "Native iOS 26+ with full XCTest tier strategy",
            "Display P3 WCS brand system (indigo, emerald, bronze, pearl)",
            "TestFlight live on App Store Connect (App ID 6770373495)",
        ],
    )

    page_text(
        pdf,
        "Market Opportunity",
        "Construction digitization is accelerating",
        [
            "Global BIM software spend continues to grow as owners mandate digital "
            "deliverables (IFC, COBie) and field teams demand real-time model access.",
            "Mobile-first workflows are under-served: most incumbents remain desktop-centric "
            "with poor offline UX and weak AR integration.",
            "AI-assisted concept design is emerging; teams want governed prompts tied to "
            "project context, not generic chat tools.",
        ],
        [
            "TAM: BIM + field collaboration + mobile construction software",
            "SAM: iOS-first professional users in ENR Top contractors and design firms",
            "SOM: Pilot verticals - commercial hubs, airport terminals, infrastructure",
        ],
    )

    page_text(
        pdf,
        "The Solution",
        "Six workflows, one shell",
        [
            "A single tab-based shell covers Projects, Site, AR, AI, Export, and Settings. "
            "Project-aware navigation ensures AR and export always bind to the active model.",
            "Parametric libraries and design program installers seed realistic demo and "
            "pilot environments in seconds.",
            "Inspector sheets and workspace segmentation support deep parametric editing "
            "without leaving the field context.",
        ],
    )

    for filename, title, caption in PROMOS:
        page_feature(pdf, filename, title, caption)

    page_text(
        pdf,
        "WCS Design System",
        "Premium, accessible, testable",
        [
            "Tokens-first palette: Deep Indigo primary, Emerald Teal success, Bronze "
            "highlights, cool slate neutrals, and pearl shimmer on hero cards only.",
            "PrimaryButton, CardView, InspectorSheet, and StatusChip components ship in-app "
            "with accessibilityIdentifier coverage for XCUITest.",
            "Contrast targets meet Apple HIG: 4.5:1 body text, shape + color for status chips.",
        ],
    )

    page_text(
        pdf,
        "Technology Platform",
        "Built for reliability and scale",
        [
            "SwiftUI + SwiftData core with CloudKit optional sync and relationship inverses "
            "for production store integrity.",
            "StoreKit 2 subscriptions (Pro / Team / Enterprise) with admin access registry "
            "and App Store Connect TestFlight automation scripts.",
            "Layered CI: fast unit, PR gate smoke UI, nightly regression, release candidate "
            "workflows on GitHub Actions.",
        ],
        [
            "OpenAI integration for governed design prompts",
            "IFC, COBie, PDF, DWG handoff export pipeline",
            "ARSite + RoomPlan hooks for spatial capture",
        ],
    )

    page_text(
        pdf,
        "Business Model",
        "Recurring SaaS on App Store",
        [
            "Monthly subscriptions via StoreKit: Pro ($19.99), Team ($49.99), Enterprise ($149.99) "
            "with feature gating on export, AI, CloudKit, and seat count.",
            "Admin CLI grants TestFlight access and tier entitlements; bundled access_registry "
            "supports pilot enterprises before IAP propagation.",
            "Future: seat-based Team dashboard, SSO, and private CloudKit containers for GCs.",
        ],
    )

    page_text(
        pdf,
        "Go-To-Market",
        "TestFlight to App Store",
        [
            "Current TestFlight program on App Store Connect with scripted beta invites and "
            "external groups for design partners.",
            "PR gate: unit + smoke UI on every pull request; main branch enforced CI.",
            "Vertical design packs (commercial, airport) accelerate land-and-expand within accounts.",
        ],
    )

    page_text(
        pdf,
        "Roadmap, Investment & Use of Funds",
        "18-month execution plan",
        [
            "Q1-Q2: App Store 1.0, subscription merchandising, analytics, crash-free sessions > 99.5%.",
            "Q3: iPad sidebar shell, clash/issue BCF-lite, expanded COBie validation.",
            "Q4: Enterprise SSO, admin web console for access registry, EU data residency option.",
            "Shipping product on device today - not a prototype deck. Defensible mobile + offline-first "
            "architecture with full test pyramid and WCS premium brand differentiation.",
        ],
        [
            "40% engineering (iOS + cloud)",
            "25% GTM and pilot customer success",
            "20% design / compliance / App Store",
            "15% operations and legal",
            "Expansion: Pro -> Team -> Enterprise seats",
        ],
    )

    page_closing(pdf)

    pdf.output(str(OUT))
    print(OUT, f"({pdf.page_no()} pages)")


if __name__ == "__main__":
    build()
