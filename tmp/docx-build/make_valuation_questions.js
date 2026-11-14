const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, WidthType, ShadingType,
  BorderStyle, AlignmentType, HeadingLevel, LevelFormat,
} = require('docx');

const FONT = 'Arial';
const W = [700, 5626, 2700];
const border = { style: BorderStyle.SINGLE, size: 4, color: 'BFBFBF' };
const borders = { top: border, bottom: border, left: border, right: border };
const cell = (text, w, head) => new TableCell({
  width: { size: w, type: WidthType.DXA }, borders,
  margins: { top: 80, bottom: 80, left: 100, right: 100 },
  shading: head ? { type: ShadingType.CLEAR, fill: '1F3864' } : undefined,
  children: [new Paragraph({ children: [new TextRun({ text, font: FONT, size: 20, bold: !!head, color: head ? 'FFFFFF' : '000000' })] })],
});
const table = (rows) => new Table({
  width: { size: 9026, type: WidthType.DXA }, columnWidths: W,
  rows: [
    new TableRow({ tableHeader: true, children: [cell('No.', W[0], true), cell('Question', W[1], true), cell('Your answer', W[2], true)] }),
    ...rows.map(([n, q]) => new TableRow({ cantSplit: true, children: [cell(String(n), W[0]), cell(q, W[1]), cell('', W[2])] })),
  ],
});
const h = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun({ text: t, font: FONT })] });
const p = (t) => new Paragraph({ spacing: { after: 120 }, children: [new TextRun({ text: t, font: FONT, size: 22 })] });
const bullet = (t) => new Paragraph({ numbering: { reference: 'bul', level: 0 }, spacing: { after: 40 }, children: [new TextRun({ text: t, font: FONT, size: 22 })] });

const done = [
  'General Details: Estate type removed; Property Type list with bedrooms; Construction, Year Built, Extension, Listed Building as you wrote them; New Build Property removed.',
  'Accommodation: one screen with the Inspection fields; Parking Locations removed; Location & Amenities and Road removed.',
  'Property Inspection: Condition is now good, reasonable, fair, poor, very poor everywhere.',
  'Outside Property: Roof, Rainwater Goods, Chimney, Main Walls, Windows, External Decorations/finishes, Floor, Garage, Outbuilding with your lists and sentences.',
  'Flat roof: Partial view and Visibility condition removed. Main Wall: Building movement none / minor movement / significant movement.',
  'Inside Property: Roof Space, Walls, Kitchen, Bathroom, Damp, Damp Source with your lists and sentences.',
  'Services: Electricity Metre, Gas, Water, Heating, Water Heating with your location and boiler lists.',
  'Overall Condition: Reasonable / Reasonable with repair. Other Matters and Energy Performance (EPC) removed.',
  'Valuation: the "agreed purchase price of ... appears reasonable" sentence with figures and words. Purpose of Valuation now has Staircasing.',
  'New section "Significant Valuation Consideration" (Roof, External Wall Cladding, Building Movement, Damp, Timber Defects, Other Concerns) with your lists and sentences.',
  'Every "Other" opens a text box.',
  'Report: same section names, colour bars, two-column element boxes, cover, header and footer as your sample, in Word and PDF.',
];
const Q = [
  [1, 'Construction: your typed list (traditional masonry, solid wall, cavity wall, timber frame, steel frame, concrete wall, precast concrete panels, system-built, other construction) and your handwritten note (Solid brick / cavity wall, Stud wall, Timber frame, Concrete frame, Other) are different. We used the typed list. Is that right?'],
  [2, 'Gas: OK and Water: OK (handwritten note). What should "OK" do on these screens?'],
  [3, 'Electricity, Mains, Location: Dated (handwritten note). Where should "Dated" go? (A tick next to the meter location, or a separate tick?) The existing "Old" tick already prints "dated".'],
  [4, 'Valuation: Edit / General Remark... (the photo is cut off at the edge). What should change on Valuation or General Remarks?'],
  [5, 'Age of Extension (Date of Extension): which sentence should it print? Today the date is stored but not printed (the typed Year Built and Extension sentences have no place for it).'],
  [6, 'Condition "Fair" and "Very poor": we print "The ... has been assessed as fair." and "... as very poor." Do you want other sentences? (Good, Reasonable and Poor use the sentences that were already approved.)'],
  [7, 'Roof: your list contains flat-roof materials (mineral felt, rubber membrane, single-ply membrane). We put it on the Pitched Roof screen (shown as "Roof" in the report) and left Flat Roof and Other Roof as they were. Is that right?'],
  [8, 'Floor is now one list ("Floors are of ..."), Garage and Outbuilding are tick lists, and Internal Fittings is replaced by Kitchen and Bathroom screens. Answers saved on the old Internal Fittings screen no longer print. Is that acceptable?'],
  [9, 'Your sample report has a "Limitations" block under Restrictions. Should the valuation app get a Limitations screen? (It is not in your typed list.)'],
  [10, 'Your sample report has an "FBS Valuation Matrix" (comparables table) under Valuation. Should the app produce it? What data does it need?'],
  [11, 'Rainwater Goods: "and associated fittings" is a tick in the list. Kitchen: the worktop locations (kitchen, utility room, other) print before "worktops comprise". Please check these two sentences.'],
  [12, 'Significant Valuation Consideration, Timber Defects: "Extensive Dry Rot" is written twice in your file. We made one tick. Was another item meant (for example Wet Rot)?'],
  [13, 'Significant Valuation Consideration: which colour should its section bar have? (Not given; red was used.)'],
];

const doc = new Document({
  styles: {
    default: { document: { run: { font: FONT, size: 22 } } },
    paragraphStyles: [
      { id: 'Title', name: 'Title', basedOn: 'Normal', run: { font: FONT, size: 40, bold: true, color: '1F3864' }, paragraph: { spacing: { before: 0, after: 120 } } },
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { font: FONT, size: 26, bold: true, color: '1F3864' }, paragraph: { spacing: { before: 320, after: 120 }, keepNext: true, outlineLevel: 0 } },
    ],
  },
  numbering: { config: [{ reference: 'bul', levels: [{ level: 0, format: LevelFormat.BULLET, text: '\u2022', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 270 } } } }] }] },
  sections: [{
    properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1134, right: 1440, bottom: 1134, left: 1440 } } },
    children: [
      new Paragraph({ style: 'Title', children: [new TextRun({ text: 'SurveyScriber: Valuation changes, questions', font: FONT })] }),
      p('What is done from your Valuation Feed back of 13 November and your handwritten note, and what we need from you. 14 November 2026.'),
      h('Done (please test)'),
      ...done.map(bullet),
      h('Please answer'),
      table(Q),
      new Paragraph({ spacing: { before: 240 }, children: [new TextRun({ text: 'Thank you.', font: FONT, size: 22 })] }),
    ],
  }],
});
Packer.toBuffer(doc).then((buf) => {
  const out = 'E:/survey-scriber/docs/client-valuation-2026-11-13/Client_Questions_Valuation_14Nov2026.docx';
  fs.writeFileSync(out, buf);
  console.log('written', buf.length);
});
