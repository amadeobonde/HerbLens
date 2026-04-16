-- HerbLens Seed Data — Chamomile sample entry

insert into public.plants (
    id, common_name, alternate_names, origin, regions_found, climates,
    growing_conditions, image_url, thumbnail_url, description, tags,
    category, featured, access_tier, suggested_prompts
) values (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'Chamomile',
    array['German Chamomile', 'Wild Chamomile', 'Matricaria'],
    'Western Europe and Western Asia',
    array['Europe', 'North America', 'Australia', 'South America'],
    array['temperate', 'mediterranean'],
    'Full sun to partial shade, well-drained soil, tolerates poor soil',
    'https://cdn.herblens.app/plants/chamomile.jpg',
    'https://cdn.herblens.app/plants/chamomile_thumb.jpg',
    'A gentle, daisy-like herb prized for centuries as a natural remedy for relaxation, digestive comfort, and skin health.',
    array['calming', 'digestive', 'anti-inflammatory', 'sleep', 'skin'],
    'Flower',
    true,
    'free',
    array[
        'Can I take chamomile with melatonin?',
        'Is chamomile safe for kids?',
        'How often can I drink chamomile tea?',
        'What''s the difference between German and Roman chamomile?'
    ]
);

-- Chamomile uses
insert into public.plant_uses (plant_id, category, description, access_tier) values
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Nervous System',
     'Widely used to promote relaxation and support restful sleep. Contains apigenin, which binds to brain receptors that reduce anxiety.',
     'free'),
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Digestive',
     'Soothes upset stomach, reduces bloating, and may relieve symptoms of IBS and indigestion.',
     'free'),
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Skin',
     'Applied topically to calm irritated skin, reduce redness, and support wound healing.',
     'free');

-- Chamomile contraindications
insert into public.plant_contraindications (plant_id, condition, details, severity) values
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Ragweed allergy',
     'Chamomile is in the same family as ragweed. People with ragweed allergies may experience allergic reactions.',
     'high'),
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Blood thinners',
     'Chamomile contains coumarin, which may increase the effect of anticoagulant medications.',
     'moderate'),
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Pregnancy',
     'Large amounts may stimulate uterine contractions. Small amounts in tea are generally considered safe, but consult your doctor.',
     'moderate');

-- Chamomile recipes
insert into public.recipes (
    id, plant_id, title, type, difficulty, prep_time,
    steep_or_cure_time, yield, access_tier, image_url
) values
    ('r1a2b3c4-d5e6-7890-abcd-ef1234567890',
     'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
     'Classic Chamomile Sleep Tea', 'tea', 'beginner',
     '5 minutes', '5-7 minutes', '1 cup', 'premium',
     'https://cdn.herblens.app/recipes/chamomile_tea.jpg'),
    ('r2b3c4d5-e6f7-8901-bcde-f12345678901',
     'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
     'Chamomile Calming Tincture', 'tincture', 'intermediate',
     '15 minutes', '4-6 weeks', '4 oz', 'premium',
     'https://cdn.herblens.app/recipes/chamomile_tincture.jpg');

-- Tea recipe ingredients
insert into public.recipe_ingredients (recipe_id, name, amount, notes, sort_order) values
    ('r1a2b3c4-d5e6-7890-abcd-ef1234567890', 'Dried chamomile flowers', '1 tbsp', 'Use whole flowers for best flavor', 0),
    ('r1a2b3c4-d5e6-7890-abcd-ef1234567890', 'Hot water', '8 oz', 'Just below boiling, around 200°F', 1),
    ('r1a2b3c4-d5e6-7890-abcd-ef1234567890', 'Honey', '1 tsp', 'Optional, to taste', 2),
    ('r1a2b3c4-d5e6-7890-abcd-ef1234567890', 'Lemon slice', '1', 'Optional', 3);

-- Tea recipe steps
insert into public.recipe_steps (recipe_id, step_number, instruction, tip) values
    ('r1a2b3c4-d5e6-7890-abcd-ef1234567890', 1,
     'Place dried chamomile flowers into a tea infuser or directly into your cup.',
     'A mesh ball infuser works great for loose flowers.'),
    ('r1a2b3c4-d5e6-7890-abcd-ef1234567890', 2,
     'Heat water to just below boiling (about 200°F / 93°C).',
     'Boiling water can make the tea taste bitter.'),
    ('r1a2b3c4-d5e6-7890-abcd-ef1234567890', 3,
     'Pour hot water over the chamomile and let steep for 5-7 minutes.',
     'Longer steeping = stronger flavor and more compounds extracted.'),
    ('r1a2b3c4-d5e6-7890-abcd-ef1234567890', 4,
     'Remove the infuser or strain the flowers. Add honey and lemon if desired.',
     null),
    ('r1a2b3c4-d5e6-7890-abcd-ef1234567890', 5,
     'Drink 30-60 minutes before bed for best sleep benefits.',
     'Make it a nightly ritual to signal your body it''s time to wind down.');

-- Tincture recipe ingredients
insert into public.recipe_ingredients (recipe_id, name, amount, notes, sort_order) values
    ('r2b3c4d5-e6f7-8901-bcde-f12345678901', 'Dried chamomile flowers', '1/2 cup', 'Packed loosely', 0),
    ('r2b3c4d5-e6f7-8901-bcde-f12345678901', 'High-proof vodka (80-100 proof)', '1 cup', 'Must fully cover the flowers', 1),
    ('r2b3c4d5-e6f7-8901-bcde-f12345678901', 'Glass jar with tight lid', '1', 'Mason jar works well', 2);

-- Tincture recipe steps
insert into public.recipe_steps (recipe_id, step_number, instruction, tip) values
    ('r2b3c4d5-e6f7-8901-bcde-f12345678901', 1,
     'Fill your glass jar about halfway with dried chamomile flowers.',
     'Don''t pack too tightly — the alcohol needs to circulate.'),
    ('r2b3c4d5-e6f7-8901-bcde-f12345678901', 2,
     'Pour vodka over the flowers until they are fully submerged with about 1 inch of liquid above.',
     'Use 100-proof for a stronger extraction.'),
    ('r2b3c4d5-e6f7-8901-bcde-f12345678901', 3,
     'Seal the jar tightly and label it with the date.',
     null),
    ('r2b3c4d5-e6f7-8901-bcde-f12345678901', 4,
     'Store in a cool, dark place for 4-6 weeks. Shake the jar gently every few days.',
     'A kitchen cabinet away from the stove works perfectly.'),
    ('r2b3c4d5-e6f7-8901-bcde-f12345678901', 5,
     'After 4-6 weeks, strain through cheesecloth into a dark dropper bottle.',
     'Squeeze the cheesecloth to get every last drop.'),
    ('r2b3c4d5-e6f7-8901-bcde-f12345678901', 6,
     'Take 1-2 dropperfuls (30-60 drops) in water or tea as needed.',
     'Start with a smaller dose to see how your body responds.');
