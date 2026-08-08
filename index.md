---
title: Oversigt
---

{% assign sider = site.pages | where_exp: "p", "p.url != page.url" | sort: "url" %}
{% assign grupper = sider | group_by: "dir" %}
{% for g in grupper %}
## {{ g.name | remove_first: "/" | default: "Forsiden" }}
{% for p in g.items %}
- [{{ p.title | default: p.name }}]({{ p.url | relative_url }})
{% endfor %}
{% endfor %}
