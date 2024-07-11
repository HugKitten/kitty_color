-- Use pg_tle
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "pg_tle";

-- Drop extension
-- DROP EXTENSION IF EXISTS "kitty_color";
-- SELECT pgtle.uninstall_extension_if_exists('kitty_color');

-- Create extension
SELECT pgtle.install_extension(
               'kitty_color',
               '1.0',
               '4 byte argb color',
               $_pgtle_$

-- Create color
SELECT pgtle.create_shell_type_if_not_exists('public', 'color');

-- Define getting bytes from text
CREATE OR REPLACE FUNCTION public.color_in(value text)
    RETURNS bytea AS
$$
DECLARE
    _t text;
BEGIN
    -- Ensure format is correct
    _t := value;
    IF (_t !~ '^#?[A-Fa-f0-9]{6}([A-Fa-f0-9]{2})?$') THEN
        RAISE EXCEPTION 'Invalid format.';
    END IF;

    -- Trim hash tag
    _t := ltrim(_t, '#');

    -- Pad with white value
    _t := lpad(_t, 8, 'F');

    -- Convert to hex
    RETURN decode(_t, 'hex');
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;

-- Define getting text from bytes
CREATE OR REPLACE FUNCTION public.color_out(value bytea)
    RETURNS text AS
$$
DECLARE
    _t text;
BEGIN
    -- Convert to hex
    _t := encode(value, 'hex');

    -- Format it it
    _t := '#' || upper(_t);

    -- Return it
    RETURN _t;
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;

-- Create type
SELECT pgtle.create_base_type('public', 'color', 'public.color_in(text)'::regprocedure,
                                            'public.color_out(bytea)'::regprocedure, 4);

-- Constructor for clear
CREATE OR REPLACE FUNCTION public.color()
    RETURNS public.color AS
$$
BEGIN
    RETURN '#00000000'::public.color;
END
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;

-- Constructor for int
CREATE OR REPLACE FUNCTION public.color(value integer)
    RETURNS public.color AS
$$
DECLARE
    _t text;
BEGIN
    -- Ensure value is in range
    IF (value < -2147483648 OR value > 2147483647) THEN
        RAISE EXCEPTION 'Value must be within range of an 4 byte integer.';
    END IF;

    -- Convert to hex
    _t := to_hex(value);

    -- Pad to fill size
    _t := lpad(_t, 8, '0');

    -- Convert to color
    RETURN _t::public.color;
END
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;

-- Constructor for ARGB
CREATE OR REPLACE FUNCTION public.color(a integer, r integer, g integer, b integer)
    RETURNS public.color AS
$$
DECLARE
    _argb integer;
BEGIN
    -- Ensure value is in range
    IF (a < 0 OR a > 255) THEN
        RAISE EXCEPTION 'Alpha must be between 0 and 255.';
    END IF;
    IF (r < 0 OR r > 255) THEN
        RAISE EXCEPTION 'Red must be between 0 and 255.';
    END IF;
    IF (g < 0 OR g > 255) THEN
        RAISE EXCEPTION 'Green must be between 0 and 255.';
    END IF;
    IF (b < 0 OR b > 255) THEN
        RAISE EXCEPTION 'Blue must be between 0 and 255.';
    END IF;

    -- Convert to hex
    _argb :=
            (a << 24) +
            (r << 16) +
            (g << 8) +
            (b << 0);

    -- Convert to color
    RETURN public.color(_argb);
END
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;

-- Constructor for RGB
CREATE OR REPLACE FUNCTION public.color(r integer, g integer, b integer)
    RETURNS public.color AS
$$
BEGIN
    RETURN public.color(255, r, g, b);
END
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;

-- Operators
-- Convert to int4
CREATE OR REPLACE FUNCTION public.int4(value bytea)
    RETURNS int4 AS
$$
BEGIN
    RETURN (get_byte(value, 0) << 24) +
           (get_byte(value, 1) << 16) +
           (get_byte(value, 2) << 8) +
           (get_byte(value, 3) << 0);
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
SELECT pgtle.create_operator_func('public', 'color', 'public.int4(bytea)'::regprocedure);

-- Equal
CREATE OR REPLACE FUNCTION public.color_eq(l bytea, r bytea)
    RETURNS boolean AS
$$
BEGIN
    RETURN pg_catalog.byteaeq(l, r);
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
SELECT pgtle.create_operator_func('public', 'color', 'public.color_eq(bytea, bytea)'::regprocedure);
CREATE OPERATOR = (
    LEFTARG = public.color,
    RIGHTARG = public.color,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    HASHES,
    MERGES,
    PROCEDURE = public.color_eq
    );

-- Hash
CREATE OR REPLACE FUNCTION public.hash_color(value bytea)
    RETURNS int4 AS
$$
BEGIN
    RETURN hashint4(public.int4(value));
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
SELECT pgtle.create_operator_func('public', 'color', 'public.hash_color(bytea)'::regprocedure);
CREATE OPERATOR CLASS public.color_ops
    DEFAULT FOR TYPE public.color USING hash AS
    OPERATOR 1 = ,
    FUNCTION 1 public.hash_color(public.color);

-- Compare
CREATE OR REPLACE FUNCTION public.color_cmp(l bytea, r bytea)
    RETURNS integer AS
$$
BEGIN
    RETURN pg_catalog.byteacmp(l, r);
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
SELECT pgtle.create_operator_func('public', 'color', 'public.color_cmp(bytea, bytea)'::regprocedure);
CREATE OPERATOR CLASS public.color_ops
    DEFAULT FOR TYPE public.color USING btree AS
    OPERATOR 1 = ,
    FUNCTION 1 public.color_cmp(public.color, public.color);

-- Not equal
CREATE OR REPLACE FUNCTION public.color_ne(l bytea, r bytea)
    RETURNS boolean AS
$$
BEGIN
    RETURN pg_catalog.byteane(l, r);
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
SELECT pgtle.create_operator_func('public', 'color', 'public.color_ne(bytea, bytea)'::regprocedure);
CREATE OPERATOR <> (
    LEFTARG = public.color,
    RIGHTARG = public.color,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel,
    HASHES,
    MERGES,
    PROCEDURE = public.color_ne
    );

-- Get value
CREATE OR REPLACE FUNCTION public.color_get_char(input public.color, value_type char)
    RETURNS integer AS
$$
BEGIN
    CASE value_type
        WHEN 'a' THEN RETURN get_byte(input::bytea, 0);
        WHEN 'r' THEN RETURN get_byte(input::bytea, 1);
        WHEN 'g' THEN RETURN get_byte(input::bytea, 2);
        WHEN 'b' THEN RETURN get_byte(input::bytea, 3);
        ELSE RAISE EXCEPTION 'Only ARGB values are supported';
        END CASE;
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
CREATE OPERATOR -> (
    LEFTARG = public.color,
    RIGHTARG = char,
    COMMUTATOR = ->,
    PROCEDURE = public.color_get_char
    );

-- Set value no subscripting :(
CREATE OR REPLACE FUNCTION public.color_set(value public.color, color_type char, color_value integer)
    RETURNS public.color AS
$$
DECLARE
    _b bytea;
    _h text;
BEGIN
    -- Convert to bytes
    _b := value::bytea;

    -- Override color
    CASE color_type
        WHEN 'a' THEN _b := set_byte(_b, 0, color_value);
        WHEN 'r' THEN _b := set_byte(_b, 1, color_value);
        WHEN 'g' THEN _b := set_byte(_b, 2, color_value);
        WHEN 'b' THEN _b := set_byte(_b, 3, color_value);
        ELSE RAISE EXCEPTION 'Only ARGB values are supported';
        END CASE;

    -- Convert to hex
    _h := encode(_b, 'hex');

    -- Pad with blank value
    _h := lpad(_h, 8, '0');

    -- Convert to color
    return _h::public.color;
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;

-- Set values with hstore
CREATE OR REPLACE FUNCTION public.color_set(value public.color, store hstore)
    RETURNS public.color AS
$$
DECLARE
    _r public.color;
    _k text;
    _v text;
BEGIN
    _r := coalesce(value, color());
    FOREACH _k IN ARRAY akeys(store)
    LOOP
        _v := store -> _k;
        _r := coalesce(color_set(_r, _k, _v::integer), _r);
    END LOOP;
    RETURN _r;
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
CREATE OPERATOR #= (
    LEFTARG = public.color,
    RIGHTARG = hstore,
    COMMUTATOR = #=,
    PROCEDURE = public.color_set
    );

-- Contains operator
CREATE OR REPLACE FUNCTION public.color_contains(input public.color, key char, value integer)
    RETURNS boolean AS
$$
BEGIN
    RETURN public.color_get_char(input, char) == value;
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
   CREATE OR REPLACE FUNCTION public.color_contains(input public.color, store hstore)
    RETURNS boolean AS
$$
DECLARE
    _c hstore;
BEGIN
    _c['a'] := public.color_get_char(input, 'a');
    _c['r'] := public.color_get_char(input, 'r');
    _c['g'] := public.color_get_char(input, 'g');
    _c['b'] := public.color_get_char(input, 'b');
    RETURN _c @> store;
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
CREATE OPERATOR @> (
    LEFTARG = public.color,
    RIGHTARG = hstore,
    COMMUTATOR = @>,
    PROCEDURE = public.color_contains,
    RESTRICT = contsel,
    JOIN = contjoinsel
    );

-- Shift left
CREATE OR REPLACE FUNCTION public.color_shl(l public.color, r integer)
    RETURNS integer AS
$$
BEGIN
    RETURN pg_catalog.int4shl(public.int4(l), r);
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
CREATE OPERATOR << (
    LEFTARG = public.color,
    RIGHTARG = integer,
    COMMUTATOR = <<,
    PROCEDURE = public.color_shl
    );

-- Shift right
CREATE OR REPLACE FUNCTION public.color_shr(l public.color, r integer)
    RETURNS integer AS
$$
BEGIN
    RETURN pg_catalog.int4shr(public.int4(l), r);
END;
$$ IMMUTABLE
   STRICT LANGUAGE plpgsql;
CREATE OPERATOR >> (
    LEFTARG = public.color,
    RIGHTARG = integer,
    COMMUTATOR = >>,
    PROCEDURE = public.color_shr
    );

$_pgtle_$
       );
-- CREATE EXTENSION IF NOT EXISTS "kitty_color";
