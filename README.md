# pg_tle_color
Small script to add a color type to postgresql using amazon's pg_tle extension. Internally all colors are stored as a int4 (4 byte integer)

# Installation
1. Install the [pg_tle](https://github.com/aws/pg_tle) extension.
3. Install the [color](https://github.com/HugKitten/pg_tle_color/blob/main/color_install.sql) extension.
4. Enable the color extension using `CREATE EXTENSION IF NOT EXISTS "kitty_color";`

## Inserting color
```
CREATE TABLE colors(
  -- color takes up 4 bytes (a byte for Alpha, Red, Green, and Blue)
  -- Float ARGB values not supported
  myColor color NOT NULL
);
INSERT INTO colors(myColor)
  -- Clear color
  VALUES (color())
  -- ARGB color
         (color(255, 255, 0, 0))
  -- RGB color
         (color(0, 255, 255))
  -- Hex color
         ('#FFFFFF')
  -- Without hash tag
         ('FFFFFF')
  -- With alpha
         ('#FFFFFFFF')
  -- Without hash tag and with alpha
         ('#FFFFFF')
```

## Reading ARGB Values 
```
-- ARGB values
SELECT c -> 'a' as 'alpha',
       c -> 'r' as 'red',
       c -> 'g' as 'green',
       c -> 'b' as 'blue'
FROM colors c;
-- integer
SELECT int4(c)
FROM colors c;
-- #FFFFFFFF format
SELECT c
FROM colors c;
-- With functions
SELECT color_get_char(c, 'a') as 'alpha',
       color_get_char(c, 'r') as 'red',
       color_get_char(c, 'g') as 'green',
       color_get_char(c, 'b') as 'blue'
FROM 'colors' c;
```

## Updating values
```
-- Set all values to have alpha of 255
UPDATE colors SET myColor = myColor #= 'a => 255';
-- Using functions
UPDATE colors SET myColor = color_set_char(myColor, 'a', 255);
-- Using hstore
UPDATE colors SET myColor = color_set_char(myColor, 'a => 255');
```

## Selecting values
-- Get all values with alpha of 255
SELECT myColor FROM colors WHERE myColor @> 'a => 255';
-- Using functions
SELECT myColor FROM colors WHERE color_contains(myColor, 'a', 255);
-- Using hstore
SELECT myColor FROM colors WHERE color_contains(myColor, 'a => 255');
```

# Considerations
### Why did you create this?
I created this because I didn't like that there weren't any extensions that could store colors as 4 byte integers internally, so I created a small little extension to do that for me.

### Can you add x feature?
Feel free to request any feature, and I'll consider adding it. This project does everything I need it to, so I don't plan on changing the script further. That being said, feel free to fork my project or create pull requests with changes you've made.

### Unsupported features
Currently the script could be improved with the following features, but there are no plains to support them at the moment.
- CMYK format
- Float and other numeric version of properties
- Brightness value
- Hue value
- Saturation value
- Tint value
- Shade value
- Outputting in RGB hex format #FFFFFF instead of #FFFFFFFF
- Other color formats
- Custom encode/decode modes

### Types that may be added in the future to support these features
- ColorF type for ARGB colors in float format
- RGB type for RGB colors without alpha
- RGBF type for RGB colors without alpha in float format
- Methods to output color in desired format using string codes ``color_to_string(myColor, 'R:int, B:int, G:int, A:float')`` for example.
- More decode, and encode options
