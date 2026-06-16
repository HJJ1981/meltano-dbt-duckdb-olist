{% macro generate_surrogate_key(field_list) %}

    {# This macro takes a list of columns, coalesces them to handle nulls, and hashes them into an MD5 surrogate key #}
    md5(cast(
        {% for field in field_list %}
            coalesce(cast({{ field }} as string), '')
            {% if not loop.last %} || '-' || {% endif %}
        {% endfor %}
    as string))

{% endmacro %}