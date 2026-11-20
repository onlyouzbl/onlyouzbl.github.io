---
layout: lab
permalink: /lab/
title: LIN-AI Lab
description: The Multimodal Understanding and Retrieval Lab at Ningbo University, led by Bolin Zhang.
---

<section id="about" class="intro" aria-labelledby="about-heading">
  <img src="/assets/img/lin-ai-lab.svg" width="1400" height="580" alt="LIN-AI Lab · 麟智实验室">
  <div>
    <h2 id="about-heading">About the Lab</h2>
    <p>The Multimodal Understanding and Retrieval Lab (LIN-AI Lab) was founded at Ningbo University on <time datetime="2026-11-05">November 5, 2026</time>. Led by <a href="/">Bolin Zhang</a>, the lab focuses on multimodal retrieval. We study how a query in one form, such as a sentence, can help us find relevant information in another, such as a video.</p>
    <p class="motto"><em>Bringing talent together, shaping the future through intelligence.</em> <span lang="zh-CN">麟聚英才，智启未来</span></p>
  </div>
</section>

<section id="news" markdown="0">
  <h2>Lab News</h2>
  <p><a href="/#news">News from Bolin Zhang’s homepage</a></p>
  {% include journal-news.liquid %}
</section>

<section id="members" aria-labelledby="members-heading">
  <h2 id="members-heading">Lab Members</h2>
  <div class="lab-lead">
    <h3><a href="/">Bolin Zhang <span lang="zh-CN">张博麟</span></a></h3>
    <p>Lab Director</p>
    <p><strong>Research interests</strong> · Multimodal retrieval and video moment retrieval from large video collections.</p>
  </div>
  <div class="cohort">
    <div><h3>Students</h3><p>Entered <time datetime="2026-09">September 2026</time></p></div>
    <div class="students">
      {% for slot in (1..2) %}
      <div class="student">
        <div class="student-photo" aria-label="Student photo, pending" role="img"></div>
        <dl>
          <dt>English name</dt><dd></dd>
          <dt>Chinese name</dt><dd></dd>
          <dt>Research interests</dt><dd></dd>
        </dl>
      </div>
      {% endfor %}
    </div>
  </div>
</section>

<section id="research" markdown="0">
  <h2>Research Areas</h2>
  {% for area in site.data.lab_research %}
  <article class="research-row">
    <div class="research-media">
      <img loading="lazy" width="440" height="232" src="/assets/img/lab-research/{{ area.asset }}.png" data-animation="/assets/img/lab-research/{{ area.asset }}.gif" alt="{{ area.alt | escape }}">
      <button type="button" hidden aria-label="Play animation: {{ area.title | escape }}">Play</button>
    </div>
    <div><h3>{{ area.title }}</h3><p>{{ area.description }}</p></div>
  </article>
  {% endfor %}
</section>

<section id="publications" markdown="0">
  <h2>Lab Publications</h2>
  <p><a href="/#publications">Publications on Bolin Zhang’s homepage</a></p>
  <details class="lab-publications">
    <summary>View all publications ({% bibliography_count %})</summary>
    {% bibliography --template home-citation %}
  </details>
</section>

<section id="lab-life" markdown="0">
  <h2>Lab Life</h2>
  {% if site.data.lab_activities.size > 0 %}
    <div class="activity-gallery">
      {% for activity in site.data.lab_activities %}
        <figure><img loading="lazy" src="{{ activity.photo | relative_url | escape }}" alt="{{ activity.alt | escape }}"><figcaption>{{ activity.caption | escape }}</figcaption></figure>
      {% endfor %}
    </div>
  {% else %}
    <p>Photos and stories from lab outings, group activities, and shared meals will appear here.</p>
  {% endif %}
</section>
