ALTER TABLE flavor_tags DROP CONSTRAINT IF EXISTS flavor_tags_profile_check;
ALTER TABLE flavor_tags ADD CONSTRAINT flavor_tags_profile_check
  CHECK (profile IN ('berry','fruit','citrus','dessert','beverage','herbal','spicy','fresh'));

ALTER TABLE private_tobacco_products DROP CONSTRAINT IF EXISTS private_product_profiles_valid;
ALTER TABLE private_tobacco_products ADD CONSTRAINT private_product_profiles_valid
  CHECK (flavor_profiles <@ ARRAY['berry','fruit','citrus','dessert','beverage','herbal','spicy','fresh']::text[]);
