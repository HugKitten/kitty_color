# pg_tle_color
Small script to add a color type to postgresql using amazon's pg_tle extension

Simply run the provided script (after installing the [pg_tle](https://github.com/aws/pg_tle) extension) to add a new color type to the database.

# Examples
The following example is going to assume you have the following table:
```
CREATE TABLE colors(
  myColor color NOT NULL
);
```

## Adding colors
### Hex color
```
INSERT INTO colors VALUES('#FF0000');
```

### Seperate RGB value
```
INSERT INTO colors VALUES(rgb(255, 0, 0));
```

### Seperate ARGB value
```
INSERT INTO colors VALUES(rgb(255, 255, 0, 0));
```

### ARGB number
```
INSERT INTO colors VALUES(argb(-1894835));
```

## Updating colors

### Update all colors to have an alpha of 255
Other values are 'r' for red, 'g' for green and 'b' for blue
```
UPDATE colors set myColor = set_color_value(myColor, 'a', 255)
WHERE get_color_value(myColor, 'a') != 255;
```

## Reading colors
### Hex
```
SELECT myColor FROM colors;
```

### ARGB integer
```
SELECT get_argb(myColor) FROM colors;
```
