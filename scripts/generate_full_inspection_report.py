"""
Generate a complete non-AI Property Inspection report from inspection_tree.json.

Outputs:
1) PDF report with all sections/screens/fields
2) JSON answer snapshot used in the report
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Tuple

from fpdf import FPDF, XPos, YPos


ROOT = Path(__file__).resolve().parents[1]
TREE_PATH = ROOT / "assets" / "property_inspection" / "inspection_tree.json"
OUTPUT_DIR = ROOT / "generated_reports"


@dataclass
class FieldRow:
    field_id: str
    label: str
    field_type: str
    value: str
    conditional_on: str
    conditional_value: str
    conditional_mode: str


class InspectionPdf(FPDF):
    ACCENT = (21, 101, 192)
    DARK = (33, 33, 33)
    MEDIUM = (97, 97, 97)
    LIGHT = (245, 245, 245)
    WHITE = (255, 255, 255)

    def __init__(self) -> None:
        super().__init__(orientation="P", unit="mm", format="A4")
        self.set_auto_page_break(auto=True, margin=18)
        self.set_margins(15, 15, 15)
        self.alias_nb_pages()

    def header(self) -> None:
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "B", 9)
        self.set_text_color(*self.ACCENT)
        self.cell(90, 7, "RICS HomeBuyer Report (Home Survey Inspection Report)")
        self.set_font("Helvetica", "", 8)
        self.set_text_color(*self.MEDIUM)
        self.cell(0, 7, "SurveyScriber - Non-AI Sample Export", align="R", new_x=XPos.LEFT, new_y=YPos.NEXT)
        self.set_draw_color(*self.ACCENT)
        self.set_line_width(0.2)
        self.line(15, self.get_y(), 195, self.get_y())
        self.ln(3)

    def footer(self) -> None:
        self.set_y(-12)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(*self.MEDIUM)
        self.cell(0, 8, f"Page {self.page_no()}/{{nb}}", align="C")

    def cover(self, survey_ref: str) -> None:
        self.add_page()
        self.set_fill_color(*self.ACCENT)
        self.rect(0, 0, 210, 55, "F")

        self.set_xy(15, 16)
        self.set_font("Helvetica", "B", 20)
        self.set_text_color(*self.WHITE)
        self.multi_cell(180, 9, "RICS HomeBuyer Report\n(Home Survey Inspection Report)", align="C")

        self.set_text_color(*self.DARK)
        self.set_y(70)
        self.set_font("Helvetica", "B", 13)
        self.cell(0, 8, "Complete Property Inspection (Non-AI Sample)", new_x=XPos.LEFT, new_y=YPos.NEXT, align="C")
        self.ln(3)

        self.set_font("Helvetica", "", 10)
        self.cell(0, 7, f"Survey Reference: {survey_ref}", new_x=XPos.LEFT, new_y=YPos.NEXT, align="C")
        self.cell(0, 7, f"Generated At: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", new_x=XPos.LEFT, new_y=YPos.NEXT, align="C")
        self.cell(0, 7, "AI Content: Disabled", new_x=XPos.LEFT, new_y=YPos.NEXT, align="C")

    def section_header(self, key: str, title: str) -> None:
        self.add_page()
        self.set_fill_color(*self.ACCENT)
        self.rect(15, self.get_y(), 180, 10, "F")
        self.set_text_color(*self.WHITE)
        self.set_font("Helvetica", "B", 12)
        self.set_xy(18, self.get_y() + 1.8)
        self.cell(0, 6, f"Section {key}: {title}")
        self.ln(10)
        self.ln(2)

    def screen_header(self, title: str, screen_id: str) -> None:
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(*self.DARK)
        self.multi_cell(0, 6, f"{title}  [{screen_id}]")
        self.ln(1)

    def field_table(self, rows: List[FieldRow]) -> None:
        if not rows:
            self.set_font("Helvetica", "I", 9)
            self.set_text_color(*self.MEDIUM)
            self.cell(0, 6, "No fields available on this screen.", new_x=XPos.LEFT, new_y=YPos.NEXT)
            self.ln(2)
            return

        headers = ["Field", "Type", "Value", "Conditional Rule"]
        widths = [55, 18, 62, 45]
        self.set_font("Helvetica", "B", 8)
        self.set_fill_color(*self.LIGHT)
        self.set_text_color(*self.DARK)
        for h, w in zip(headers, widths):
            self.cell(w, 6.5, h, border=1, fill=True)
        self.ln()

        self.set_font("Helvetica", "", 8)
        for row in rows:
            cond = ""
            if row.conditional_on:
                cond = f"{row.conditional_mode or 'show'}: {row.conditional_on}={row.conditional_value}"

            line_items = [f"{row.label} ({row.field_id})", row.field_type, row.value, cond]
            line_counts = [self._line_count(text, width) for text, width in zip(line_items, widths)]
            max_lines = max(line_counts) if line_counts else 1
            row_height = max_lines * 4.5

            if self.get_y() + row_height > 275:
                self.add_page()
                self.set_font("Helvetica", "B", 8)
                self.set_fill_color(*self.LIGHT)
                for h, w in zip(headers, widths):
                    self.cell(w, 6.5, h, border=1, fill=True)
                self.ln()
                self.set_font("Helvetica", "", 8)

            x0 = self.get_x()
            y0 = self.get_y()
            for i, (text, width) in enumerate(zip(line_items, widths)):
                x = x0 + sum(widths[:i])
                self.set_xy(x, y0)
                self.multi_cell(width, 4.5, text, border=1)
                self.set_xy(x + width, y0)
            self.set_xy(x0, y0 + row_height)
        self.ln(2)

    def _line_count(self, text: str, width: float) -> int:
        if not text:
            return 1
        words = text.split()
        if not words:
            return 1
        lines = 1
        current = ""
        for word in words:
            test = word if not current else f"{current} {word}"
            if self.get_string_width(test) <= width - 2:
                current = test
            else:
                lines += 1
                current = word
        return lines


def _sample_value(field: Dict[str, Any], index: int) -> str:
    ftype = (field.get("type") or "text").lower()
    options = field.get("options") or []
    label = field.get("label") or field.get("id") or "Field"

    if ftype == "label":
        return "N/A"
    if ftype == "checkbox":
        return "true" if index % 2 == 0 else "false"
    if ftype == "number":
        return str((index % 5) + 1)
    if ftype == "dropdown":
        for option in options:
            opt = str(option).strip()
            if opt:
                return opt
        return "Not specified"
    return f"Sample input for {label}"


def build_snapshot(tree: Dict[str, Any]) -> Tuple[List[Dict[str, Any]], Dict[str, Dict[str, str]]]:
    sections = tree.get("sections", [])
    answers: Dict[str, Dict[str, str]] = {}
    normalized_sections: List[Dict[str, Any]] = []

    for section in sections:
        sec_key = section.get("key", "")
        sec_title = section.get("title", sec_key)
        nodes = section.get("nodes", [])
        norm_nodes: List[Dict[str, Any]] = []

        for node in nodes:
            node_id = node.get("id", "")
            node_title = node.get("title", node_id)
            fields = node.get("fields", [])

            rows: List[FieldRow] = []
            node_answers: Dict[str, str] = {}
            for i, f in enumerate(fields):
                fid = f.get("id", "")
                value = _sample_value(f, i)
                node_answers[fid] = value
                rows.append(
                    FieldRow(
                        field_id=fid,
                        label=f.get("label", fid),
                        field_type=f.get("type", "text"),
                        value=value,
                        conditional_on=f.get("conditionalOn", "") or "",
                        conditional_value=f.get("conditionalValue", "") or "",
                        conditional_mode=f.get("conditionalMode", "") or "",
                    )
                )
            answers[node_id] = node_answers
            norm_nodes.append({"id": node_id, "title": node_title, "rows": rows})

        normalized_sections.append({"key": sec_key, "title": sec_title, "nodes": norm_nodes})

    return normalized_sections, answers


def main() -> None:
    if not TREE_PATH.exists():
        raise FileNotFoundError(f"inspection tree not found: {TREE_PATH}")

    with TREE_PATH.open("r", encoding="utf-8") as f:
        tree = json.load(f)

    sections, answers = build_snapshot(tree)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    survey_ref = f"INSP-{stamp}"
    pdf_path = OUTPUT_DIR / f"property_inspection_full_non_ai_{stamp}.pdf"
    json_path = OUTPUT_DIR / f"property_inspection_full_non_ai_answers_{stamp}.json"

    pdf = InspectionPdf()
    pdf.cover(survey_ref=survey_ref)

    for section in sections:
        pdf.section_header(section["key"], section["title"])
        for node in section["nodes"]:
            pdf.screen_header(node["title"], node["id"])
            pdf.field_table(node["rows"])

    pdf.output(str(pdf_path))

    with json_path.open("w", encoding="utf-8") as f:
        json.dump(
            {
                "surveyReference": survey_ref,
                "generatedAt": datetime.now().isoformat(),
                "aiIncluded": False,
                "sourceTree": str(TREE_PATH),
                "answers": answers,
            },
            f,
            indent=2,
            ensure_ascii=False,
        )

    total_sections = len(sections)
    total_screens = sum(len(s["nodes"]) for s in sections)
    total_fields = sum(len(n["rows"]) for s in sections for n in s["nodes"])

    print(f"PDF: {pdf_path}")
    print(f"Answers JSON: {json_path}")
    print(f"Sections: {total_sections}")
    print(f"Screens: {total_screens}")
    print(f"Fields: {total_fields}")


if __name__ == "__main__":
    main()
