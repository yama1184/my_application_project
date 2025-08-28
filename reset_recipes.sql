DELETE FROM recipes;

INSERT INTO recipes (dish_name, ingredients, image_url, season) VALUES
('鮭ときのこのホイル焼き', '["鮭", "きのこ"]', 'https://example.com/salmon.jpg', '秋'),
('ぶり大根', '["ぶり", "大根"]', 'https://example.com/buri.jpg', '冬'),
('冷製トマトパスタ', '["パスタ", "トマト", "バジル"]', 'https://example.com/pasta.jpg', '夏'),
('春キャベツと豚バラ肉の回鍋肉', '["春キャベツ", "豚バラ肉"]', 'https://example.com/hoikoro.jpg', '春'),
('冷しゃぶサラダ', '["豚肉", "きゅうり", "トマト", "レタス"]', 'https://example.com/reishabu.jpg', '夏'),
('麻婆茄子', '["豚ひき肉", "なす", "ピーマン", "生姜"]', 'https://example.com/mabonasu.jpg', '夏'),
('鶏肉と根菜の煮物', '["鶏もも肉", "にんじん", "ごぼう", "レンコン"]', 'https://example.com/ninben.jpg', '秋'),
('肉じゃが', '["牛肉", "じゃがいも", "玉ねぎ", "にんじん"]', 'https://example.com/nikujaga.jpg', '秋'),
('おでん', '["大根", "卵", "ちくわ", "こんにゃく"]', 'https://example.com/oden.jpg', '冬');