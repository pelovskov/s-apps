---
layout: default
title: Oversigt
---
## Søg
<div style="margin-bottom: 2rem;">
  <input type="text" id="search-input" placeholder="Søg i filerne..." style="width: 100%; padding: 10px; font-size: 1.1em; border-radius: 5px; border: 1px solid #ccc;">
  <ul id="search-results" style="list-style: none; padding-left: 0; margin-top: 10px;"></ul>
</div>

<script>
  // Hent vores dynamiske JSON-fil
  fetch('{{ site.baseurl }}/search.json')
    .then(response => response.json())
    .then(data => {
      const searchInput = document.getElementById('search-input');
      const searchResults = document.getElementById('search-results');

      // Lyt efter hvert tastetryk i søgefeltet
      searchInput.addEventListener('input', function(e) {
        const query = e.target.value.toLowerCase();
        searchResults.innerHTML = ''; // Ryd forrige resultater

        // Vent med at søge til der er skrevet mindst 2 bogstaver
        if (query.length < 2) return; 

        // Filtrer i JSON-dataen (søger i både titel og brødtekst)
        const results = data.filter(post => 
          post.title.toLowerCase().includes(query) || 
          post.content.toLowerCase().includes(query)
        );

        if (results.length === 0) {
          searchResults.innerHTML = '<li style="color: #666;">Ingen resultater fundet...</li>';
          return;
        }

        // Udskriv resultaterne som links
        results.forEach(result => {
          const li = document.createElement('li');
          li.style.marginBottom = '8px';
          li.innerHTML = `<a href="${result.url}" style="font-weight: bold;">${result.title}</a>`;
          searchResults.appendChild(li);
        });
      });
    });
</script>

# Indholdsfortegnelse

{% assign grouped_pages = site.pages | group_by: "dir" %}

{% for group in grouped_pages %}
  {% comment %} Rens mappenavnet for skråstreger {% endcomment %}
  {% assign folder_name = group.name | remove_first: "/" | remove_last: "/" %}
  
  {% comment %} Giv rodmappen et pænt navn {% endcomment %}
  {% if folder_name == "" %}
    {% assign folder_name = "Filer i hovedmappen" %}
  {% endif %}

  <details style="margin-bottom: 10px; cursor: pointer;">
    <summary style="font-size: 1.2em; font-weight: bold; padding: 5px 0;">
      📁 {{ folder_name | capitalize }}
    </summary>
    
    <ul style="margin-top: 8px;">
      {% for page in group.items %}
        {% if page.name != 'index.md' and page.name != '404.html' %}
          <li>
            <a href="{{ site.baseurl }}{{ page.url }}">
              {{ page.title | default: page.name }}
            </a>
          </li>
        {% endif %}
      {% endfor %}
    </ul>
  </details>
{% endfor %}

Spændende
