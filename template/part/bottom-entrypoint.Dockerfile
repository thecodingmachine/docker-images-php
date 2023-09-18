ENTRYPOINT ["/init", "/opt/tcm-bin/run-as-user"]
ADD --chown=root --chmod=655 /bin /opt/tcm-bin
{% if image.variant == "apache" -%}
CMD ["bash"]
{%- else %}
CMD ["echo", "overwrite with your custom command"]
{%- endif %}
USER root