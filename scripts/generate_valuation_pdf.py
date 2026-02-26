"""
Generate a professional RICS Valuation Report PDF from the text report.
Uses fpdf2 to create a polished, multi-section PDF document.
"""
import re
import os
from fpdf import FPDF, XPos, YPos
from datetime import datetime


def sanitize(text):
    """Replace unicode chars that break latin-1 encoding."""
    replacements = {
        '\u2018': "'", '\u2019': "'",
        '\u201c': '"', '\u201d': '"',
        '\u2013': '-', '\u2014': '--',
        '\u2026': '...', '\u00a0': ' ',
        '\u00a3': 'GBP', '\u20ac': 'EUR',
        '\n': ' ',
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text.encode('latin-1', errors='replace').decode('latin-1')


class RICSValuationPDF(FPDF):
    """Custom PDF class for RICS Valuation Report styling."""

    ACCENT = (0, 77, 64)             # #004D40 deep teal
    DARK = (33, 33, 33)
    MEDIUM = (97, 97, 97)
    LIGHT_BG = (245, 245, 245)
    WHITE = (255, 255, 255)
    SECTION_COLORS = {
        'valuation_details': (0, 77, 64),         # Deep Teal
        'property_assessment': (21, 101, 192),     # Blue
        'property_inspection': (46, 125, 50),      # Green
        'condition_restrictions': (211, 47, 47),   # Red
        'valuation_completion': (103, 58, 183),    # Deep Purple
    }
    SECTION_LABELS = {
        'valuation_details': '1 - Valuation Details',
        'property_assessment': '2 - Property Assessment',
        'property_inspection': '3 - Property Inspection',
        'condition_restrictions': '4 - Condition & Restrictions',
        'valuation_completion': '5 - Valuation & Completion',
    }

    def __init__(self):
        super().__init__(orientation='P', unit='mm', format='A4')
        self.set_auto_page_break(auto=True, margin=25)
        self.set_margins(20, 20, 20)

    def header(self):
        if self.page_no() == 1:
            return
        # Left: report type (bold accent), Center: property, Right: company
        y = self.get_y()
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*self.ACCENT)
        self.cell(60, 8, 'RICS Property Valuation', align='L')
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(*self.MEDIUM)
        self.cell(50, 8, '42 Victoria Gardens', align='C')
        self.set_text_color(*self.DARK)
        self.cell(0, 8, 'SurveyScriber',
                  new_x=XPos.LEFT, new_y=YPos.NEXT, align='R')
        self.set_draw_color(*self.ACCENT)
        self.set_line_width(0.3)
        self.line(20, self.get_y(), 190, self.get_y())
        self.ln(5)

    def footer(self):
        self.set_y(-20)
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(*self.MEDIUM)
        self.cell(0, 10, f'Page {self.page_no()}/{{nb}}', align='C')

    def cover_page(self, meta):
        self.add_page()
        # Deep teal accent bar (80mm, matching inspection style)
        self.set_fill_color(*self.ACCENT)
        self.rect(0, 0, 210, 80, 'F')

        # Title block — centered in accent bar
        self.set_y(18)
        self.set_font('Helvetica', 'B', 28)
        self.set_text_color(*self.WHITE)
        self.cell(0, 12, 'Valuation Report', new_x=XPos.LEFT, new_y=YPos.NEXT, align='C')
        self.ln(2)
        self.set_font('Helvetica', '', 14)
        self.cell(0, 8, 'Mortgage Valuation Report', new_x=XPos.LEFT, new_y=YPos.NEXT, align='C')
        self.ln(4)
        self.set_font('Helvetica', 'B', 11)
        self.cell(0, 8, 'Prepared in accordance with RICS Valuation Standards',
                  new_x=XPos.LEFT, new_y=YPos.NEXT, align='C')

        # Property title — centered below bar
        self.set_y(95)
        self.set_text_color(*self.DARK)
        self.set_font('Helvetica', 'B', 18)
        self.cell(0, 10, sanitize(meta['title']), new_x=XPos.LEFT, new_y=YPos.NEXT, align='C')
        if meta.get('address') and meta['address'] != meta['title']:
            self.set_font('Helvetica', '', 12)
            self.set_text_color(*self.MEDIUM)
            self.cell(0, 7, sanitize(meta['address']),
                      new_x=XPos.LEFT, new_y=YPos.NEXT, align='C')
        self.ln(5)

        # Property details table (matching inspection layout)
        details = [
            ('Property Address', meta['address']),
            ('Client Name', meta['client']),
            ('Job Reference', meta['job_ref']),
            ('Inspection Date', meta['date']),
            ('Report Generated', datetime.now().strftime('%d %B %Y')),
            ('Survey Duration', meta['duration']),
            ('Valuation Type', 'Market Value - Mortgage'),
            ('Purchase Price', meta.get('purchase_price', 'GBP 850,000')),
        ]

        start_y = self.get_y()
        row_h = 10
        self.set_fill_color(*self.LIGHT_BG)
        self.set_draw_color(200, 200, 200)

        for i, (label, value) in enumerate(details):
            y = start_y + i * row_h
            fill = i % 2 == 0
            self.set_xy(35, y)
            self.set_font('Helvetica', 'B', 10)
            self.set_text_color(*self.MEDIUM)
            self.cell(50, row_h, label, border=0, fill=fill)
            self.set_font('Helvetica', '', 10)
            self.set_text_color(*self.DARK)
            self.cell(90, row_h, sanitize(value), border=0, fill=fill,
                      new_x=XPos.LEFT, new_y=YPos.NEXT)

        # Bottom disclaimer
        self.set_y(240)
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(*self.MEDIUM)
        self.multi_cell(0, 4,
            'This report is for the sole use of the named client and the mortgage '
            'lender. It should not be relied upon by any third party.',
            align='C')

        self.ln(5)
        self.set_font('Helvetica', 'B', 9)
        self.set_text_color(*self.ACCENT)
        self.cell(0, 6, 'SurveyScriber Professional Report',
                  new_x=XPos.LEFT, new_y=YPos.NEXT, align='C')

    def toc_page(self, sections):
        self.add_page()
        self.set_font('Helvetica', 'B', 20)
        self.set_text_color(*self.ACCENT)
        self.cell(0, 12, 'Table of Contents', new_x=XPos.LEFT, new_y=YPos.NEXT)
        self.ln(5)
        self.set_draw_color(*self.ACCENT)
        self.set_line_width(0.5)
        self.line(20, self.get_y(), 190, self.get_y())
        self.ln(8)

        for key, title, screen_count in sections:
            color = self.SECTION_COLORS.get(key, self.ACCENT)
            label = self.SECTION_LABELS.get(key, title)
            self.set_fill_color(*color)
            self.rect(20, self.get_y() + 1, 3, 6, 'F')

            self.set_x(26)
            self.set_font('Helvetica', 'B', 11)
            self.set_text_color(*self.DARK)
            self.cell(120, 8, sanitize(label))
            self.set_font('Helvetica', '', 9)
            self.set_text_color(*self.MEDIUM)
            self.cell(0, 8, f'{screen_count} items',
                      new_x=XPos.LEFT, new_y=YPos.NEXT, align='R')
            self.ln(1)

    def section_header(self, key, title):
        if self.get_y() > 240:
            self.add_page()
        else:
            self.ln(5)

        color = self.SECTION_COLORS.get(key, self.ACCENT)
        label = self.SECTION_LABELS.get(key, title)
        self.set_fill_color(*color)
        self.rect(20, self.get_y(), 170, 12, 'F')
        self.set_font('Helvetica', 'B', 13)
        self.set_text_color(*self.WHITE)
        self.set_x(25)
        self.cell(0, 12, sanitize(label),
                  new_x=XPos.LEFT, new_y=YPos.NEXT)
        self.ln(5)

    def screen_header(self, title, is_merged=False):
        if self.get_y() > 255:
            self.add_page()

        self.set_draw_color(*self.ACCENT)
        self.set_line_width(0.8)
        self.line(20, self.get_y(), 20, self.get_y() + 7)

        self.set_x(23)
        self.set_font('Helvetica', 'B', 11)
        self.set_text_color(*self.DARK)
        self.cell(0, 7, sanitize(title), new_x=XPos.LEFT, new_y=YPos.NEXT)
        self.ln(2)

    def phrase_paragraph(self, text):
        if self.get_y() > 265:
            self.add_page()

        self.set_font('Helvetica', '', 10)
        self.set_text_color(*self.DARK)
        text = sanitize(text.strip())
        if not text:
            return

        # Valuation amount styling
        if 'open market value' in text.lower() or 'purchase price' in text.lower():
            self.set_font('Helvetica', 'B', 10)
            self.set_text_color(0, 77, 64)  # Teal
            self.set_x(22)
            self.multi_cell(166, 5, text, align='L')
            self.ln(2)
            self.set_text_color(*self.DARK)
            return

        # Legal advice / your legal adviser styling
        if 'your legal adviser' in text.lower():
            self.set_font('Helvetica', 'I', 9)
            self.set_text_color(183, 28, 28)  # Red
            self.set_x(22)
            self.multi_cell(166, 5, text, align='L')
            self.ln(2)
            self.set_text_color(*self.DARK)
            return

        # Condition rating
        if 'considered satisfactory' in text or 'considered unsatisfactory' in text:
            self.set_font('Helvetica', 'I', 9)
            self.set_text_color(97, 97, 97)
            self.set_x(22)
            self.multi_cell(166, 5, text, align='L')
            self.ln(2)
            return

        # Normal paragraph
        self.set_x(22)
        self.multi_cell(166, 5, text, align='L')
        self.ln(2)

    def field_table(self, fields):
        if not fields:
            return
        if self.get_y() > 255:
            self.add_page()

        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*self.MEDIUM)
        self.set_x(22)
        self.cell(0, 5, 'Survey Data:', new_x=XPos.LEFT, new_y=YPos.NEXT)

        self.set_font('Helvetica', '', 8)
        for label, value in fields:
            if self.get_y() > 275:
                self.add_page()
            self.set_x(25)
            self.set_text_color(*self.MEDIUM)
            self.cell(55, 4, sanitize(label), border=0)
            self.set_text_color(*self.DARK)
            self.cell(0, 4, sanitize(value), border=0, new_x=XPos.LEFT, new_y=YPos.NEXT)
        self.ln(2)

    def add_separator(self):
        self.set_draw_color(220, 220, 220)
        self.set_line_width(0.2)
        self.line(25, self.get_y(), 185, self.get_y())
        self.ln(4)


def parse_report(filepath):
    """Parse the valuation text report into structured data."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract section key from "SECTION: TITLE [key]"
    section_pattern = re.compile(r'^SECTION:\s+(.+?)\s+\[(\w+)\]$')

    sections = []
    current_section = None
    current_screen = None

    lines = content.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i]

        # Section header: "SECTION: VALUATION DETAILS [valuation_details]"
        m = section_pattern.match(line.strip())
        if m:
            if current_section:
                if current_screen:
                    current_section['screens'].append(current_screen)
                    current_screen = None
                sections.append(current_section)
            current_section = {
                'key': m.group(2),
                'title': m.group(1).strip(),
                'screens': []
            }
            i += 1
            continue

        # Screen header
        if line.strip().startswith('\u250c\u2500'):  # ┌─
            if current_screen and current_section:
                current_section['screens'].append(current_screen)
            title = line.strip()[2:].strip()
            current_screen = {
                'title': title,
                'is_merged': False,
                'phrases': [],
                'fields': []
            }
            i += 1
            continue

        # Fields table
        if current_screen and '[Fields Table]' in line:
            i += 1
            while i < len(lines):
                fline = lines[i].strip()
                if fline.startswith('\u2502'):  # │
                    fline = fline[1:].strip()
                if fline.startswith('\u2514') or fline == '' or fline.startswith('\u250c'):
                    break
                if ':' in fline and fline:
                    parts = fline.split(':', 1)
                    current_screen['fields'].append(
                        (parts[0].strip(), parts[1].strip()))
                i += 1
            continue

        # Screen end
        if line.strip().startswith('\u2514'):  # └
            i += 1
            continue

        # Phrase line (│ content)
        if current_screen and line.strip().startswith('\u2502'):  # │
            phrase = line.strip()[1:].strip()
            if phrase and phrase != '\u2502':
                current_screen['phrases'].append(phrase)
            i += 1
            continue

        # Stats section
        if 'REPORT STATISTICS' in line:
            if current_section:
                if current_screen:
                    current_section['screens'].append(current_screen)
                    current_screen = None
                sections.append(current_section)
            break

        i += 1

    return sections


def generate_pdf(sections, output_path):
    """Generate a professional PDF from parsed valuation report sections."""
    pdf = RICSValuationPDF()
    pdf.alias_nb_pages()

    meta = {
        'title': 'Valuation - 42 Victoria Gardens',
        'address': '42 Victoria Gardens, Kensington, London, SW7 4QR',
        'client': 'Mr. James Richardson',
        'job_ref': 'FBVAL-LDN-2026-042',
        'date': '26 February 2026',
        'duration': '2 hours 45 minutes',
        'purchase_price': 'GBP 850,000',
    }

    # Cover page
    pdf.cover_page(meta)

    # Table of contents
    toc = [(s['key'], s['title'], len(s['screens'])) for s in sections]
    pdf.toc_page(toc)

    # Content sections
    for section in sections:
        pdf.add_page()
        pdf.section_header(section['key'], section['title'])

        for screen in section['screens']:
            pdf.screen_header(screen['title'], screen['is_merged'])

            for phrase in screen['phrases']:
                pdf.phrase_paragraph(phrase)

            if screen['fields']:
                pdf.field_table(screen['fields'])

            pdf.add_separator()

    # Statistics page
    pdf.add_page()
    pdf.set_font('Helvetica', 'B', 16)
    pdf.set_text_color(*pdf.ACCENT)
    pdf.cell(0, 12, 'Report Statistics', new_x=XPos.LEFT, new_y=YPos.NEXT)
    pdf.ln(5)

    total_phrases = sum(
        len(s['phrases'])
        for sec in sections for s in sec['screens']
    )
    total_screens = sum(len(s['screens']) for s in sections)

    stats = [
        ('Sections', str(len(sections))),
        ('Screens', str(total_screens)),
        ('Total Phrases', str(total_phrases)),
        ('Report Type', 'RICS Property Valuation'),
        ('Valuation Basis', 'Market Value - Red Book'),
        ('Generated By', 'SurveyScriber Professional'),
    ]
    for label, value in stats:
        pdf.set_font('Helvetica', 'B', 11)
        pdf.set_text_color(33, 33, 33)
        pdf.set_x(30)
        pdf.cell(60, 8, label)
        pdf.set_font('Helvetica', '', 11)
        pdf.cell(0, 8, value, new_x=XPos.LEFT, new_y=YPos.NEXT)

    pdf.output(output_path)
    print(f'PDF saved to: {output_path}')
    print(f'Pages: {pdf.page_no()}')
    print(f'Sections: {len(sections)}')
    print(f'Screens: {total_screens}')
    print(f'Phrases: {total_phrases}')


if __name__ == '__main__':
    report_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        'london_valuation_report.txt'
    )
    output_path = os.path.join(
        os.path.expanduser('~'), 'Downloads',
        'London_Property_Valuation_Report.pdf'
    )

    print(f'Reading report from: {report_path}')
    sections = parse_report(report_path)
    print(f'Parsed {len(sections)} sections')

    generate_pdf(sections, output_path)
    print(f'\nDone! Open: {output_path}')
