# Valuation Nov-13: client line -> where done -> proof

Sources: `docs/client-valuation-2026-11-13/` (typed list, sample report, handwritten note).
Tests: `test/features/property_valuation/domain/client_edits_2026_11_13_valuation_test.dart`, `test/features/report_export/data/services/valuation_report_nov13_test.dart`.
Screenshots: `tmp/client-edits-2026-11-13/proof/` (web app). Real PDF / Word pages: `proof/v17_pdf_p*.png`, `proof/v17_word_p*.png` next to the client sample `proof/sample_word_p*.png`.

| Client line | Step | Result | Proof |
|---|---|---|---|
| General Details: remove Estate type | V1 | field and sentence gone | tests V1, proof/v1v2_general_details.png |
| Property Type sentence + bedrooms (typed) | V2 | 10 options + Other text box + Bedrooms; old Type/Sub type/Flat type/Build type migrated or kept as old wording | tests V2, proof/v2_type_1.png, v2_other_2.png, v2_flat_3.png |
| Construction (typed 9 options) | V3 | 8 ticks + other construction + text box | tests V3, proof/v3_1.png, v3d_3.png, v3b_5.png |
| Year Built (typed) | V4 | year or period or unknown + client tail | tests V4, proof/v3_3.png |
| Extension (typed) + Age of Extension (Date of Extension) (note) | V5 | 7 ticks, field relabelled | tests V5, proof/v3_4.png |
| Listed Building (typed) | V6 | client sentence | tests V6 |
| New Build Property: remove (typed + note) | V7 | screen, code and answers ignored | tests V7, proof/v18sec_property_assessment_-.png |
| Accommodation (One Screen) / replace with the Inspection one / generate same (typed + note) | V8 | one 'Accommodation' screen with the Inspection fields and labels; report table with Property total row | tests V8, proof/v18_no_of_rooms.png, v17_word_p2.png |
| Remove Parking locations (note) | V8 | field and sentences gone | tests V8 |
| Location & Amenities + Road: remove (typed) | V9 | screens, engine, validator rules removed | tests V9, proof/v18sec_property_assessment_-.png |
| Property Inspection standardised Condition good-reasonable-to-poor (note) + 'Condition: good, reasonable, fair, poor, very poor' (typed) | V10 | 29 Condition dropdowns, Notes for Fair/Poor/Very poor | tests V10, proof/v18cond_1.png |
| Roof, Rainwater Goods, Chimney, Main Walls, Windows, External Decorations/finishes, Floor, Garage, Outbuilding (typed) | V11 | each list and sentence as written | tests V11, proof/v18_val_*.png, v17_word_p3..4.png |
| Flat roof: remove Partial view and Visibility condition (note) | V12 | gone from Flat Roof (Pitched/Other roof untouched) | tests V12, proof/v18_val_flat_roof.png |
| Main Wall building movement none / minor / significant (note) | V12 | options changed | tests V12 |
| Roof Space, Walls, Kitchen, Bathroom, Damp, Damp Source (typed) | V13 | each list and sentence as written; Kitchen and Bathroom are two screens | tests V13, proof/v18_val_*.png, v18damp2_2.png |
| Electricity Metre, Gas, Water, Heating, Water Heating (typed) | V14 | location ticks and boiler lists as written | tests V14, proof/v18_val_*.png |
| Overall Condition: Reasonable / Reasonable with repair (typed) | V15 | two options, client sentences | tests V15, proof/v18oc_1.png |
| Other Matters / Energy performance / EPC: remove (typed + note) | V15 | screens and code removed | proof/v18sec_condition_restrictions_-.png |
| Valuation Amount sentence (typed) | V15 | 'agreed purchase price of £x.00 (Words) appears reasonable ...' | tests V15 |
| Purpose of Valuation list with Staircasing (typed) | V15 | six options | tests V15, proof/v18purpose_1.png |
| Options: add text box to 'Other' (note) | V16 | every Other (2 dropdowns, 36 ticks) opens a text box; strict tests | tests V16, proof/v2_other_2.png, v3d_3.png |
| Report format = sample (sections, bars, colours, boxes, cover, header/footer) | V17 | Word and PDF | tests valuation_report_nov13_test, proof/v17_*.png vs sample_word_p*.png |

## Not done (client questions, see the questions file)
Gas OK / Water OK (note), Electricity 'Dated' (note), 'Valuation - Edit General Remarks' (note, cut off), Age of Extension sentence, Fair / Very poor sentences, Construction handwritten list vs typed list, sample's Limitations block and FBS Valuation Matrix picture.

## Not tested
Phone / APK (not built in this round), live server, signature and photo pages in the sample (only the bar colour is tested), Word signature images.
