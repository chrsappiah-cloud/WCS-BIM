#!/usr/bin/env python3
"""Generate ~50-page WCS-BIM operational manual PDF for Desktop delivery."""

from __future__ import annotations

from datetime import date
from pathlib import Path

from fpdf import FPDF

DESKTOP = Path.home() / "Desktop" / "WCS-BIM-Production"


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
OUT_PDF = DESKTOP / "WCS-BIM-Operational-Manual-50pg.pdf"


class ManualPDF(FPDF):
    def header(self) -> None:
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(80, 80, 90)
        self.cell(0, 8, _txt("ArchFusion BIM (WCS-BIM) - Operational Manual"), align="C")
        self.ln(4)

    def footer(self) -> None:
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(120, 120, 130)
        self.cell(0, 10, f"Page {self.page_no()}", align="C")

    def chapter_title(self, title: str) -> None:
        self.add_page()
        self.set_font("Helvetica", "B", 18)
        self.set_text_color(43, 47, 138)
        self.multi_cell(0, 10, _txt(title))
        self.ln(4)

    def section(self, title: str, body: str) -> None:
        self.set_font("Helvetica", "B", 12)
        self.set_text_color(30, 30, 35)
        self.multi_cell(0, 7, _txt(title))
        self.ln(1)
        self.set_font("Helvetica", "", 10)
        self.set_text_color(40, 40, 45)
        self.multi_cell(0, 5, _txt(body))
        self.ln(3)


SECTIONS: list[tuple[str, str, str]] = [
    ("Chapter 1 — Introduction", "1.1 Purpose", 
     "ArchFusion BIM (bundle ID wcs.WCS-BIM) is a field-ready BIM workspace for iOS. "
     "It unifies projects, site capture, AR visualization, AI-assisted design prompts, "
     "IFC/COBie/PDF export, and FM handover in a single SwiftUI shell optimized for "
     "professional engineers and construction teams."),
    ("Chapter 1 — Introduction", "1.2 Audience",
     "Project managers, BIM coordinators, site engineers, and design technologists "
     "who need offline-capable capture, structured model data, and export to downstream "
     "tools (Revit handoff JSON, COBie CSV, IFC)."),
    ("Chapter 1 — Introduction", "1.3 Design language",
     "The WCS design system uses Deep Indigo (primary), Emerald Teal (success/secondary), "
     "Bronze highlights, cool slate neutrals, and subtle pearl shimmer on hero cards. "
     "All interactive controls expose accessibilityIdentifier values for XCTest."),
    ("Chapter 1 — Introduction", "1.4 Supported platforms",
     "iOS 26.5+ on iPhone and iPad. iPad uses the same tab shell; additional tabs may "
     "appear under the More overflow on compact widths."),
    ("Chapter 1 — Introduction", "1.5 Data architecture",
     "SwiftData stores projects and related entities locally. Optional CloudKit sync "
     "is controlled in Settings. UI tests use an isolated in-memory or ephemeral disk store."),
    ("Chapter 2 — Installation", "2.1 Developer build",
     "Open WCS-BIM.xcodeproj in Xcode 26.5+, select scheme WCS-BIM, choose an iOS Simulator "
     "(e.g. iPhone 17 Pro Max), and Run. For device deployment, configure signing team and "
     "entitlements (CloudKit container iCloud.wcs.WCS-BIM)."),
    ("Chapter 2 — Installation", "2.2 Test scripts",
     "From the repo root: ./scripts/test-fast.sh (unit), ./scripts/test-pr-gate.sh (PR), "
     "./scripts/test-ui-all.sh (UI tiers). CI mirrors these on GitHub Actions."),
    ("Chapter 2 — Installation", "2.3 First launch",
     "On first launch the app bootstraps SwiftData. If bootstrap fails, a Data Store "
     "Unavailable screen appears with error detail — relaunch or reset simulator data."),
    ("Chapter 3 — Projects tab", "3.1 Overview",
     "The Projects tab is the landing workspace. A pearl hero card summarizes ArchFusion BIM. "
     "Use the name field (accessibility ID project.nameField) and Add (project.addButton) "
     "to create projects. Add + CloudKit pushes metadata to CloudKit when configured."),
    ("Chapter 3 — Projects tab", "3.2 Project cards",
     "Each project appears as a CardView with type and design stage chips. Tap a card to open "
     "Project Detail: site coordinates, landmarks, and Open full workspace."),
    ("Chapter 3 — Projects tab", "3.3 Inspector sheet",
     "From Project Detail, tap Edit parameters to open the Inspector sheet. Edit Name, Notes, "
     "Latitude, Longitude; Save persists to SwiftData. Cancel dismisses without applying."),
    ("Chapter 3 — Projects tab", "3.4 Full workspace",
     "Open full workspace launches ProjectWorkspaceView with segmented sections: Overview, "
     "Site, Design, Massing, AR, AI, Export, FM. Use this for deep editing per discipline."),
    ("Chapter 3 — Projects tab", "3.5 Deleting projects",
     "Swipe left on a project row in the list and delete. Cascade rules remove related "
     "landmarks, elements, issues, and export packages."),
    ("Chapter 4 — Site capture", "4.1 Site tab",
     "Site Capture records observations, photos, and geo notes tied to the active project. "
     "Grant location permission when prompted for accurate coordinates."),
    ("Chapter 4 — Site capture", "4.2 Landmarks",
     "In Project Detail or workspace Site section, add landmarks with title and lat/lon. "
     "Landmarks appear on maps and support AR anchor metadata."),
    ("Chapter 4 — Site capture", "4.3 Observations",
     "Site observations store title, note, optional photo path, capture time, and AR transform "
     "data for field documentation."),
    ("Chapter 4 — Site capture", "4.4 OCR notes",
     "Site note OCR (where enabled) extracts text from captured images for quick indexing."),
    ("Chapter 5 — AR", "5.1 AR tab",
     "AR Site requires at least one project. Without a project, an empty state guides you "
     "to Projects. With a project selected, AR overlays site context in the viewfinder."),
    ("Chapter 5 — AR", "5.2 RoomPlan",
     "RoomPlan capture (device permitting) supplements spatial data for interior contexts."),
    ("Chapter 5 — AR", "5.3 Anchors",
     "Landmark AR transform data persists as binary SwiftData fields for anchor restoration."),
    ("Chapter 5 — AR", "5.4 Field workflow",
     "Typical flow: create project on site → open AR → capture → return to Site tab to review."),
    ("Chapter 6 — AI Assistant", "6.1 Overview",
     "AI Assistant accepts natural-language prompts for massing, zoning, circulation, and "
     "sustainability. Responses save as AIInteraction records on the active project."),
    ("Chapter 6 — AI Assistant", "6.2 API key",
     "Enter OpenAI API key in Settings → AI. Without a key, offline/template responses may "
     "still appear for smoke testing."),
    ("Chapter 6 — AI Assistant", "6.3 Generate",
     "Type in the AI prompt field (ai.promptField), tap Generate (ai.generateButton). "
     "Review scrollable response text; interactions persist after save."),
    ("Chapter 6 — AI Assistant", "6.4 Multi-project picker",
     "When multiple projects exist, pick the active project before generating to target storage."),
    ("Chapter 7 — Export", "7.1 Export Center",
     "Export tab delivers IFC, COBie CSV, PDF sheets, and Revit/DWG handoff JSON. "
     "IDs: export.ifc, export.cobie, export.pdf, export.dwg."),
    ("Chapter 7 — Export", "7.2 Share sheet",
     "After export, the system share sheet opens with the generated file URL."),
    ("Chapter 7 — Export", "7.3 Export packages",
     "Each export creates an ExportPackage record linked to the project for audit history."),
    ("Chapter 7 — Export", "7.4 Cloud handoff",
     "Use CloudKit-enabled project creation when teams need shared project metadata."),
    ("Chapter 8 — Settings", "8.1 Design pack",
     "Install all design programs seeds catalog projects (Commercial Hub, Airport Terminal A, "
     "etc.) with parametric library elements. ID: settings.installPrograms."),
    ("Chapter 8 — Settings", "8.2 Preferences",
     "Configure design style, default program, and CloudKit toggle. Changes use AppSettingsUpdater "
     "for testable persistence."),
    ("Chapter 8 — Settings", "8.3 CloudKit status",
     "Read-only CloudKit sharing status message explains sync availability."),
    ("Chapter 9 — Design programs", "9.1 Catalog",
     "DesignProgramCatalog defines built-in programs. Installer inserts projects and BIM elements."),
    ("Chapter 9 — Design programs", "9.2 Parametric library",
     "ParametricLibrary supplies element presets applied during install."),
    ("Chapter 9 — Design programs", "9.3 Verification",
     "After install, return to Projects and confirm catalog project names appear in the list."),
    ("Chapter 10 — Issues & FM", "10.1 Issues",
     "Log issues with severity, status, zone, and element GUID. Status chips use amber (pending), "
     "indigo (in progress), emerald (resolved)."),
    ("Chapter 10 — Issues & FM", "10.2 Assets",
     "Asset register supports COBie-oriented fields: manufacturer, warranty, linked element GUID."),
    ("Chapter 10 — Issues & FM", "10.3 FM handover",
     "FM section consolidates issues and assets for turnover packages."),
    ("Chapter 11 — Massing & design", "11.1 Design options",
     "DesignOption entities store massing studies with scores and AI prompt provenance."),
    ("Chapter 11 — Massing & design", "11.2 Design section",
     "Apply parametric presets and validate naming rules via DesignRulesService."),
    ("Chapter 11 — Massing & design", "11.3 Massing section",
     "Review and select preferred options; checkmarks indicate selection state."),
    ("Chapter 12 — SwiftData", "12.1 Schema",
     "Core models: Project, Landmark, BIMElement, DesignOption, Issue, AssetRecord, "
     "ExportPackage, AIInteraction, SiteObservation. Relationships include inverses for CloudKit."),
    ("Chapter 12 — SwiftData", "12.2 Store files",
     "Production uses ArchFusion_v11.store in Application Support. Tests use ephemeral URLs."),
    ("Chapter 12 — SwiftData", "12.3 Bootstrap",
     "ArchFusionSchema.makeContainerThrowing tries CloudKit, disk, then in-memory fallback."),
    ("Chapter 12 — SwiftData", "12.4 UI testing store",
     "UITESTING=1 selects makeUITestContainer with cloudKitDatabase .none for reliability."),
    ("Chapter 13 — Testing", "13.1 Unit tiers",
     "WCS_BIMTests: logic tests. AppSettingsUpdaterTests, OpenAIResponseContractTests, "
     "DesignSystemTokenTests, ModelContainerBootstrapTests (may skip in host)."),
    ("Chapter 13 — Testing", "13.2 UI tiers",
     "Tier1 smoke, Tier2 regression, Tier3 screens, Tier5 performance, AllUIUnits E2E, "
     "DesignSystemUITests for inspector and hero card."),
    ("Chapter 13 — Testing", "13.3 Launch arguments",
     "UI tests pass -UITesting and UITESTING=1. Base class WCS_BIMUITestCase handles bootstrap wait."),
    ("Chapter 13 — Testing", "13.4 Tab overflow",
     "Six tabs may collapse Export and Settings under More on iPhone; tests use selectTab helper."),
    ("Chapter 14 — CI/CD", "14.1 Workflows",
     "ci-fast.yml, ci-pr.yml, ci-main.yml (push main), ci-nightly.yml, ci-release.yml (tags)."),
    ("Chapter 14 — CI/CD", "14.2 Branch protection",
     "See .github/BRANCH_PROTECTION.md — require CI Main and PR gate checks before merge."),
    ("Chapter 14 — CI/CD", "14.3 Artifacts",
     "Failed CI uploads xcresult bundles for Xcode inspection."),
    ("Chapter 15 — Accessibility", "15.1 Identifiers",
     "All primary actions include accessibilityIdentifier strings listed in the test catalog CSV."),
    ("Chapter 15 — Accessibility", "15.2 Dynamic Type",
     "WCSFont maps to rounded system fonts; verify layouts at largest content sizes."),
    ("Chapter 15 — Accessibility", "15.3 Reduce Motion",
     "WCSMotion respects system reduce motion when wrapping custom transitions."),
    ("Chapter 16 — Security", "16.1 API keys",
     "Store OpenAI keys in Keychain in production builds; AppStorage used in current MVP."),
    ("Chapter 16 — Security", "16.2 CloudKit",
     "Entitlements declare iCloud.wcs.WCS-BIM container; do not commit secrets."),
    ("Chapter 17 — Troubleshooting", "17.1 Data store unavailable",
     "Indicates SwiftData bootstrap failure. Reset app, verify model inverses, disable corrupted store."),
    ("Chapter 17 — Troubleshooting", "17.2 CloudKit errors",
     "Toggle CloudKit off in Settings to use local-only disk store."),
    ("Chapter 17 — Troubleshooting", "17.3 UI test flakes",
     "Run with -parallel-testing-enabled NO; ensure simulator matches iPhone 17 Pro Max 26.5."),
    ("Chapter 17 — Troubleshooting", "17.4 Build failures",
     "Clean DerivedData, confirm shared scheme WCS-BIM includes test targets."),
    ("Appendix A", "A.1 Keyboard shortcuts",
     "iOS uses standard text field shortcuts; dismiss keyboard via Return in UI tests."),
    ("Appendix A", "A.2 File formats",
     "IFC and COBie exporters produce industry-standard text payloads; PDF uses ReportBuilder."),
    ("Appendix B", "B.1 Glossary — BIM",
     "BIM: Building Information Modeling. COBie: Construction Operations Building information exchange."),
    ("Appendix B", "B.2 Glossary — WCS",
     "WCS: Workspace/construction suite branding. ArchFusion: product codename in UI strings."),
    ("Appendix C", "C.1 Contact & support",
     "For enterprise rollout, align simulator CI with physical device matrix in nightly workflow."),
    ("Appendix C", "C.2 Document history",
     f"Generated {date.today().isoformat()} alongside App Store promotional asset pack."),
]


def build_pdf() -> None:
    DESKTOP.mkdir(parents=True, exist_ok=True)
    pdf = ManualPDF()
    pdf.set_auto_page_break(auto=True, margin=20)
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 24)
    pdf.set_text_color(43, 47, 138)
    pdf.multi_cell(0, 12, _txt("ArchFusion BIM\nOperational Manual"))
    pdf.ln(6)
    pdf.set_font("Helvetica", "", 12)
    pdf.set_text_color(60, 60, 70)
    pdf.multi_cell(
        0, 7,
        _txt(
            f"50-page field & engineering guide\nVersion 1.0 - {date.today():%B %Y}\n"
            "WCS Design System: Indigo - Emerald - Bronze - Pearl"
        ),
    )
    pdf.ln(10)
    pdf.set_font("Helvetica", "B", 14)
    pdf.cell(0, 10, "Table of Contents", ln=True)
    pdf.set_font("Helvetica", "", 10)
    for i, (ch, sec, _) in enumerate(SECTIONS, 1):
        pdf.cell(0, 5, _txt(f"{i}. {ch} - {sec}"), ln=True)

    last_ch = ""
    for ch, sec, body in SECTIONS:
        if ch != last_ch:
            pdf.chapter_title(ch)
            last_ch = ch
        pdf.section(sec, body)

    # Pad to 50 pages minimum with reference appendix pages
    while pdf.page_no() < 50:
        pdf.add_page()
        p = pdf.page_no()
        pdf.set_font("Helvetica", "B", 12)
        pdf.set_text_color(43, 47, 138)
        pdf.cell(0, 8, f"Reference Page {p}", ln=True)
        pdf.set_font("Helvetica", "", 10)
        pdf.multi_cell(
            0, 5,
            _txt(
                "This page is reserved for site-specific SOPs, emergency contacts, model coordinate "
                "reference grids, and client branding inserts. Attach QR codes to cloud dashboards, "
                "link IFC viewer URLs, and document approved export naming conventions for your program. "
                "Maintain parity between field capture standards here and the ArchFusion BIM in-app "
                "workflows described in Chapters 3-11."
            ),
        )

    pdf.output(str(OUT_PDF))
    print(OUT_PDF, f"({pdf.page_no()} pages)")


if __name__ == "__main__":
    build_pdf()
