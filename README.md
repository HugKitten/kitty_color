# kitty_color
Small script to add a color type to postgresql using amazon's pg_tle extension.

# Installation
1. Install the [pg_tle](https://github.com/aws/pg_tle) extension.
3. Install the [kitty_color](https://github.com/HugKitten/pg_tle_color/blob/main/color_install.sql) extension. (Run the script)
4. Enable the extension using `CREATE EXTENSION IF NOT EXISTS "kitty_color";`

## Inserting color
***The following code assumes the following***
```pgsql
CREATE TABLE colors(
  myColor color NOT NULL
);
```

**Inserting color**
```pgsql
INSERT INTO colors(myColor) VALUES (color(255, 0, 128));      -- Red, Green, Blue
INSERT INTO colors(myColor) VALUES ('#FF007E');               -- RGB hex
INSERT INTO colors(myColor) VALUES ('FF007E');                -- Without Hashtag
```

**Inserting transparrent color alpha**
```pgsql
INSERT INTO colors(myColor) VALUES (color(64, 128, 0, 255));  -- Alpha, Red, Green, Blue
INSERT INTO colors(myColor) VALUES ('#407E00FF');             -- ARGB Hex
INSERT INTO colors(myColor) VALUES ('407E00FF');              -- Without Hashtag
INSERT INTO colors(myColor) VALUES (1081999615);              -- ARGB int
INSERT INTO colors(myColor) VALUES (color());                 -- Clear
```

## Selecting colors
**Whole value** 
```pgsql
SELECT c FROM colors c;                                       -- ARGB Hex
SELECT c::int4 FROM colors c;                                 -- ARGB int
SELECT int4(c) FROM colors c;                                 -- Using function
```

**Individual values**
```pgsql
SELECT c -> 'a' as 'alpha',
       c -> 'r' as 'red',
       c -> 'g' as 'green',
       c -> 'b' as 'blue'
FROM colors c;

-- Using function 
SELECT color_get_char(c, 'a') as 'alpha',
       color_get_char(c, 'r') as 'red',
       color_get_char(c, 'g') as 'green',
       color_get_char(c, 'b') as 'blue'
FROM colors c;
```

## Updating ARGB values
```pgsql
UPDATE colors SET myColor = myColor #= 'a => 64, r => 128, g => 0, b => 255';
UPDATE colors SET myColor = myColor #= 'a => 64';
UPDATE colors SET myColor = myColor #= 'r => 128';
UPDATE colors SET myColor = myColor #= 'g => 0';
UPDATE colors SET myColor = myColor #= 'b => 255';
```

**Using functions**
```pgsql
UPDATE colors SET myColor = color_set(myColor, 'a', 64);
UPDATE colors SET myColor = color_set(myColor, 'r', 128);
UPDATE colors SET myColor = color_set(myColor, 'g', 0);
UPDATE colors SET myColor = color_set(myColor, 'b', 255);
```

**Using hstore**
```pgsql
UPDATE colors SET myColor = color_set(myColor, 'a => 64, r => 128, g => 0, b => 255');
UPDATE colors SET myColor = color_set(myColor, 'a => 64');
UPDATE colors SET myColor = color_set(myColor, 'r => 128');
UPDATE colors SET myColor = color_set(myColor, 'g => 0');
UPDATE colors SET myColor = color_set(myColor, 'b => 255');
```

## Selecting values
**Selecting values with alpha of 255**
```pgsql
SELECT myColor FROM colors WHERE myColor @> 'a => 255';
SELECT myColor FROM colors WHERE color_contains(myColor, 'a', 255);
SELECT myColor FROM colors WHERE color_contains(myColor, 'a => 255');
```

**With multiple values**
```pgsql
SELECT myColor FROM colors WHERE myColor @> 'r => 255, g => 128';
SELECT myColor FROM colors WHERE color_contains(myColor, 'r => 255, g => 128');
```

# Considerations
## Why did you create this?
I created this because I didn't like that there weren't any extensions that could store colors as 4 byte integers internally, so I created a small little extension to do that for me.

## Can you add x feature?
Feel free to request any feature, and I'll consider adding it. This project does everything I need it to, so I don't plan on changing the script further. That being said, feel free to fork my project or create pull requests with changes you've made.

## Unsupported features
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

## Types that may be added in the future to support these features
- ColorF type for ARGB colors in float format
- RGB type for RGB colors without alpha
- RGBF type for RGB colors without alpha in float format
- Methods to output color in desired format using string codes ``color_to_string(myColor, 'R:int, B:int, G:int, A:float')`` for example.
- More decode, and encode options
