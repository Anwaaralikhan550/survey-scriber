from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from fpdf import FPDF


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "generated_reports"


@dataclass(frozen=True)
class ReportSection:
    key: str
    title: str
    condition_rating: str
    paragraphs: list[str]


class ProfessionalInspectionPdf(FPDF):
    def header(self) -> None:
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(26, 63, 122)
        self.cell(0, 8, "Home Survey Inspection Report", new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(214, 220, 230)
        self.line(15, self.get_y(), 195, self.get_y())
        self.ln(4)

    def footer(self) -> None:
        self.set_y(-12)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(110, 110, 110)
        self.cell(0, 8, f"Page {self.page_no()}", align="C")

    def cover(self, property_name: str, client_name: str, reference: str) -> None:
        self.add_page()
        self.set_fill_color(26, 97, 184)
        self.rect(0, 0, 210, 58, "F")

        self.set_xy(16, 16)
        self.set_text_color(255, 255, 255)
        self.set_font("Helvetica", "B", 22)
        self.multi_cell(178, 10, "Home Survey Inspection Report", align="C")

        self.ln(18)
        self.set_text_color(33, 33, 33)
        self.set_font("Helvetica", "B", 15)
        self.multi_cell(0, 8, property_name, align="C")
        self.ln(4)
        self.set_font("Helvetica", "", 11)
        self.cell(0, 7, f"Client: {client_name}", new_x="LMARGIN", new_y="NEXT", align="C")
        self.cell(0, 7, f"Reference: {reference}", new_x="LMARGIN", new_y="NEXT", align="C")
        self.cell(
            0,
            7,
            f"Generated: {datetime.now().strftime('%d %B %Y %H:%M')}",
            new_x="LMARGIN",
            new_y="NEXT",
            align="C",
        )

        self.ln(14)
        self.set_fill_color(246, 248, 252)
        self.set_draw_color(220, 225, 235)
        self.set_line_width(0.2)
        self.multi_cell(
            0,
            7,
            (
                "This sample report has been generated as a full professional-style London property "
                "inspection document, with narrative sections, condition ratings, technical observations, "
                "risks, legal matters, and an overall opinion."
            ),
            border=1,
            fill=True,
            padding=5,
        )

    def section_heading(self, key: str, title: str) -> None:
        self.add_page()
        self.set_fill_color(39, 108, 191)
        self.set_text_color(255, 255, 255)
        self.set_font("Helvetica", "B", 14)
        self.cell(0, 10, f"{key} {title}", new_x="LMARGIN", new_y="NEXT", fill=True)
        self.ln(4)

    def condition_rating(self, rating: str) -> None:
        self.set_font("Helvetica", "B", 11)
        self.set_text_color(36, 36, 36)
        self.cell(0, 7, f"Condition rating is: {rating}.", new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

    def paragraph(self, text: str, bold_label: str | None = None) -> None:
        self.set_text_color(30, 30, 30)
        if bold_label:
            self.set_font("Helvetica", "B", 11)
            self.cell(self.get_string_width(bold_label) + 1, 7, bold_label)
            self.set_font("Helvetica", "", 11)
            self.multi_cell(0, 7, text)
        else:
            self.set_font("Helvetica", "", 11)
            self.multi_cell(0, 7, text)
        self.ln(3)


def build_sections() -> list[ReportSection]:
    return [
        ReportSection(
            key="D",
            title="About Property",
            condition_rating="1",
            paragraphs=[
                (
                    "The subject property is 42 Holland Park Avenue, London, W11 3RS. "
                    "It is a purpose-built first-floor flat forming part of a three-story brick-built "
                    "period conversion within a well-established residential terrace in West London."
                ),
                (
                    "The accommodation is understood to comprise an entrance hall, reception room, kitchen, "
                    "two bedrooms, bathroom, and ancillary storage. The property appears to have been "
                    "constructed circa 1905, with later replacement windows and modernised internal finishes."
                ),
                (
                    "When inspected, the property was occupied and furnished. The weather was dry following "
                    "a period of wet weather, which assisted the external visual appraisal of rainwater goods "
                    "and exposed elements."
                ),
            ],
        ),
        ReportSection(
            key="E",
            title="Outside the Property",
            condition_rating="2",
            paragraphs=[
                (
                    "The main walls are of solid brick construction with painted and rendered finishes in parts. "
                    "Where visible, the masonry appears generally serviceable for age and type, although routine "
                    "maintenance and localised repointing should be anticipated."
                ),
                (
                    "The roof is pitched and assumed to be timber framed beneath a tiled external covering. "
                    "Direct access was not available; however, from accessible vantage points no significant "
                    "loss of line or obvious signs of widespread failure were noted."
                ),
                (
                    "Rainwater gutters and downpipes appear to be replacement uPVC units. These were visually "
                    "serviceable at the time of inspection, though regular clearing and periodic maintenance "
                    "remains essential to reduce the risk of overflow and penetrating dampness."
                ),
                (
                    "The windows are double glazed replacement units. A representative sample was opened and "
                    "closed, and the sampled units operated satisfactorily. Minor maintenance to seals and "
                    "decorative finishes should be expected in the normal course of ownership."
                ),
                (
                    "The main entrance door and communal external joinery are functional, but decoration and "
                    "weather sealing should be reviewed as part of planned maintenance. No major immediate "
                    "external defects requiring urgent structural intervention were identified."
                ),
            ],
        ),
        ReportSection(
            key="F",
            title="Inside the Property",
            condition_rating="2",
            paragraphs=[
                (
                    "Internal ceilings, wall finishes, and partitions appear broadly serviceable and in "
                    "reasonable decorative order, subject to normal wear and tear. Isolated historic cracking "
                    "was observed, consistent with age and minor thermal movement rather than significant "
                    "ongoing structural displacement."
                ),
                (
                    "Floors are substantially concealed beneath fitted floor coverings. No lifting was undertaken. "
                    "Walkover inspection suggested generally firm underfoot performance, although limited minor "
                    "localised unevenness was noted and should be monitored as part of normal occupation."
                ),
                (
                    "Kitchen and bathroom fittings are modern and broadly functional. Flexible sealants around "
                    "sanitary fittings and worktop junctions should be maintained to prevent water penetration "
                    "to concealed timber and backing surfaces."
                ),
                (
                    "Internal woodwork, including doors, skirtings, architraves, and fitted joinery, was in "
                    "satisfactory condition at the time of inspection. Routine easing, adjustment, and periodic "
                    "redecoration will be necessary over time."
                ),
            ],
        ),
        ReportSection(
            key="G",
            title="Services",
            condition_rating="2",
            paragraphs=[
                (
                    "Services have not been tested. Comments are based upon a visual inspection only. The "
                    "electrical installation appears to include a modern consumer unit, but its age, capacity, "
                    "and certification should be confirmed by your legal adviser and electrician as appropriate."
                ),
                (
                    "Heating and hot water are understood to be provided by a gas-fired boiler serving radiators "
                    "and domestic hot water outlets. The visible installation appeared typical of a modernised "
                    "domestic system, but no operational performance testing was undertaken."
                ),
                (
                    "Visible plumbing and drainage fittings appeared generally serviceable. Any concealed defects, "
                    "including leakage, inadequate falls, or historic patch repairs, may only become apparent "
                    "upon more intrusive investigation or longer-term occupation."
                ),
            ],
        ),
        ReportSection(
            key="I",
            title="Issues for Legal Advisers",
            condition_rating="1",
            paragraphs=[
                (
                    "Your legal adviser should confirm tenure, rights of access, repairing obligations, service "
                    "charge arrangements, buildings insurance responsibility, and whether all replacement windows "
                    "and later alterations benefit from the appropriate approvals or certifications."
                ),
                (
                    "As this is a London flat, particular attention should be given to the lease term, any "
                    "upcoming major works, reserve fund provisions, and the management arrangements for communal "
                    "parts of the building."
                ),
            ],
        ),
        ReportSection(
            key="J",
            title="Risks",
            condition_rating="2",
            paragraphs=[
                (
                    "No evidence of significant structural movement, subsidence, or severe active dampness was "
                    "identified during this inspection. Nevertheless, all older London properties carry an "
                    "inherent background risk of concealed defects within inaccessible areas."
                ),
                (
                    "Ongoing maintenance of external masonry, rainwater disposal, sealants, and internal "
                    "ventilation is important to minimise the future risk of dampness, timber deterioration, "
                    "and decorative damage."
                ),
            ],
        ),
        ReportSection(
            key="O",
            title="Overall Opinion",
            condition_rating="1",
            paragraphs=[
                (
                    "In my opinion, this property is a reasonable proposition for purchase, provided you are "
                    "prepared to undertake the normal cyclical maintenance expected of a London flat of this age "
                    "and style. No major urgent defects of a structural nature were apparent within the limitations "
                    "of this inspection."
                ),
                (
                    "The property presents as a generally well-maintained residential flat in a desirable London "
                    "location. Subject to legal confirmation of tenure, management arrangements, and service "
                    "documentation, I see no reason why the property should not remain saleable in normal market "
                    "conditions."
                ),
            ],
        ),
    ]


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    reference = f"LON-INSP-{stamp}"
    output_path = OUTPUT_DIR / f"london_professional_inspection_report_{stamp}.pdf"

    pdf = ProfessionalInspectionPdf("P", "mm", "A4")
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.set_margins(15, 15, 15)
    pdf.cover(
        property_name="42 Holland Park Avenue, London, W11 3RS",
        client_name="London Residential Client",
        reference=reference,
    )

    for section in build_sections():
        pdf.section_heading(section.key, section.title)
        pdf.condition_rating(section.condition_rating)
        for paragraph in section.paragraphs:
            pdf.paragraph(paragraph)

    pdf.output(str(output_path))
    print(output_path)


if __name__ == "__main__":
    main()
