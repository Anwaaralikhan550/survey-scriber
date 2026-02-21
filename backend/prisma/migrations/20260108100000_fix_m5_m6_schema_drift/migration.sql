-- M5 Fix: Add index on surveys.created_at for efficient date-based queries
-- This enables fast ordering/filtering of surveys by creation date
CREATE INDEX "surveys_created_at_idx" ON "surveys"("created_at");

-- M6 Fix: Add unique constraint on invoice_items(invoice_id, sort_order)
-- This prevents duplicate sort_order values within the same invoice
-- ensuring line item ordering integrity
CREATE UNIQUE INDEX "invoice_items_invoice_id_sort_order_key" ON "invoice_items"("invoice_id", "sort_order");
