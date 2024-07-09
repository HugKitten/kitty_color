# pg_tle_color
Small script to add a color type to postgresql using amazon's pg_tle extension

Simply run the provided script (after installing the [pg_tle](https://github.com/aws/pg_tle) extension) to add a new color type to the database.

## Examples

### Create color table
```
CREATE TABLE colors(
  myColor color NOT NULL
);
```

### Add red color as a value to table
```
INSERT INTO colors VALUES('#FF0000');
```

### Add clear color to database (with 0 alpha)
```
INSERT INTO colors VALUES('#00000000');
```

### Add color using number
```
INSERT INTO colors VALUES(argb(-1894835));
```

### Update all colors to not be transparrent
```
UPDATE colors set myColor = set_color_value(myColor, 'a', 255)
WHERE get_color_value(myColor, 'a') != 255;
```

### Get colors as hex
```
SELECT myColor FROM colors;
```

### Get colors as argb
```
SELECT get_argb(myColor) FROM colors;
```
