# pg_tle_color
Small script to add a color type to postgresql using amazon's pg_tle extension. Internally all colors are stored as a int4 (4 byte integer)

Simply run the provided script (after installing the [pg_tle](https://github.com/aws/pg_tle) extension) to add a new color type to the database.

# Examples
The following example is going to assume you have the following table:
```
CREATE TABLE colors(
  myColor color NOT NULL
);
```

## Parsing colors
### Hex
```
INSERT INTO colors VALUES('#FF0000');
```
- Hashtag is not required.
- Supports both RGB `#FFFFFF`, and ARGB `#FFFFFFFF` format.

### Seperate Red, Green, and Blue values
```
INSERT INTO colors VALUES(rgb(255, 0, 0));
```
- Values must be between 0 and 255,
- Floats and other types not supported.

### Seperate Alpha, Red, Green, and Blue values
```
INSERT INTO colors VALUES(argb(255, 255, 0, 0));
```
- Values must be between 0 and 255,
- Floats and other types not supported.

### Number format
```
INSERT INTO colors VALUES(argb(-1894835));
```
- Values must be between -2147483648 and 2147483647.

## Updating colors
### Update all colors to have an alpha of 255
```
UPDATE colors set myColor = set_color_value(myColor, 'a', 255)
WHERE get_color_value(myColor, 'a') != 255;
```
- A for Alpha
- R for Red 
- G for Green
- B for Blue

## Formating colors
### Hex
```
SELECT myColor FROM colors;
```
- Outputs in #FFFFFFFF format
- RGB format (non-alpha) not supported.

### Integer
```
SELECT get_argb(myColor) FROM colors;
```
- Values will be between -2147483648 and 2147483647.

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
- Other output color formats
- Custom encode/decode modes

## Types that may be added in the future to support these features
- ColorF type for ARGB colors in float format
- RGB type for RGB colors without alpha
- RGBF type for RGB colors without alpha in float format
- Methods to output color in desired format using string codes ``color_to_string(myColor, 'R:int, B:int, G:int, A:float')`` for example.
- Decode, and Encode method as well as a way to set the method used to parse strings.
