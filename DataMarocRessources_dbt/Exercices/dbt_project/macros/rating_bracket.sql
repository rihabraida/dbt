{% macro rating_bracket(column_name) %}
    case
        when {{ column_name }} < 4.5 then 'low'
        when {{ column_name }} <= 4.8 then 'medium'
        when {{ column_name }} > 4.8 then 'high'
    end
{% endmacro %}