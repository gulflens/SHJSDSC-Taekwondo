-- Add athlete identity fields: dominant leg, specialty, years training
ALTER TABLE athletes ADD COLUMN IF NOT EXISTS dominant_leg text;
ALTER TABLE athletes ADD COLUMN IF NOT EXISTS specialty text;
ALTER TABLE athletes ADD COLUMN IF NOT EXISTS years_training int;
