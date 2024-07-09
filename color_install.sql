-- Use pg_tle
CREATE EXTENSION IF NOT EXISTS "pg_tle";

-- Drop extension
-- DROP EXTENSION IF EXISTS color;
SELECT pgtle.uninstall_extension_if_exists('color');

-- Create extension
SELECT pgtle.install_extension(
               'color',
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
    SELECT pgtle.create_base_type_if_not_exists('public', 'color', 'color_in(text)'::regprocedure,
                                                'color_out(bytea)'::regprocedure, 4);
  
  
    -- Convert from int
    CREATE FUNCTION public.argb(value integer)
        RETURNS color AS
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
        RETURN _t::color;
    END
    $$ IMMUTABLE
       STRICT LANGUAGE plpgsql;
       

    -- Convert to int
    CREATE FUNCTION public.get_argb(value color)
        RETURNS integer AS
    $$
    DECLARE
        _b bytea;
    BEGIN
        _b := value::bytea;
    
        RETURN 
            (get_byte(_b, 0) << 24) +
            (get_byte(_b, 1) << 16) +
            (get_byte(_b, 2) << 8) +
            (get_byte(_b, 3) << 0);
    END;
    $$ IMMUTABLE
       STRICT LANGUAGE plpgsql;
       
       
    -- Set value
    CREATE FUNCTION public.get_color_value(input color, value_type char)
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


    -- Get value
    CREATE FUNCTION public.set_color_value(value color, color_type char, color_value integer)
        RETURNS color AS
    $$
    DECLARE
        _b bytea;
        _h text;
    BEGIN
        -- Convert to bytes
        _b := value::bytea;
    
        -- Override color
        CASE color_type
            WHEN 'a' THEN
                _b := set_byte(_b, 0, color_value);
            WHEN 'r' THEN
                _b := set_byte(_b, 1, color_value);
            WHEN 'g' THEN
                _b := set_byte(_b, 2, color_value);
            WHEN 'b' THEN
                _b := set_byte(_b, 3, color_value);
            ELSE RAISE EXCEPTION 'Only ARGB values are supported';
            END CASE;
    
        -- Convert to hex
        _h := encode(_b, 'hex');
        
        -- Pad with blank value
        _h := lpad(_h, 8, '0');
        
        -- Convert to color
        return _h::color;
    END;
    $$ IMMUTABLE
       STRICT LANGUAGE plpgsql;  

$_pgtle_$
       );
-- CREATE EXTENSION "color";
